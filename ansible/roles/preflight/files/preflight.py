#!/usr/bin/env python3
import concurrent.futures
import json
import pathlib
import re
import subprocess
import sys
import time

IMAGE_RE = re.compile(r'^\s*image:\s*(\S+)')
ARCH_ALIASES = {
    'arm64': ('arm64', 'arm64v8', 'aarch64'),
    'amd64': ('amd64', 'x86_64'),
}
# Servicios amd64-only: usan tags amd64- y solo se despliegan en anton (x86_64).
# En hosts arm64 (yoda, talos) no se despliegan, así que su preflight no debe validarlos.
AMD64_ONLY_DIRS = {'jellyfin', 'sonarr', 'transmission', 'prowlarr', 'smartctl-exporter'}
MISSING_PATTERNS = re.compile(r'no such manifest|manifest unknown|not found', re.IGNORECASE)
AUTH_PATTERNS = re.compile(r'denied|unauthorized', re.IGNORECASE)
RATE_LIMIT_PATTERNS = re.compile(r'429|too many requests|toomanyrequests|rate limit', re.IGNORECASE)
RETRIES = 3
RETRY_DELAYS = (2, 4)


def collect_images(compose_root, required_arch):
    images = set()
    for compose in pathlib.Path(compose_root).rglob('compose.yaml'):
        if required_arch != 'amd64' and compose.parent.name in AMD64_ONLY_DIRS:
            continue
        for line in compose.read_text(errors='replace').splitlines():
            match = IMAGE_RE.match(line)
            if match:
                images.add(match.group(1))
    return sorted(images)


def inspect(image):
    error = ''
    for attempt in range(RETRIES):
        result = subprocess.run(
            ['docker', 'manifest', 'inspect', image],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            return {'status': 'ok', 'stdout': result.stdout}
        error = result.stderr.strip()
        if MISSING_PATTERNS.search(error):
            return {'status': 'missing', 'error': error}
        if AUTH_PATTERNS.search(error):
            return {'status': 'error', 'error': error}
        if RATE_LIMIT_PATTERNS.search(error):
            return {'status': 'ratelimit', 'error': error}
        if attempt < RETRIES - 1:
            time.sleep(RETRY_DELAYS[attempt])
    return {'status': 'error', 'error': error or 'fallo sin mensaje'}


def has_arch(manifest, required_arch, image):
    if 'manifests' in manifest:
        architectures = [
            entry.get('platform', {}).get('architecture')
            for entry in manifest['manifests']
        ]
        return required_arch in architectures
    tag = image.rsplit(':', 1)[-1].lower()
    return any(marker in tag for marker in ARCH_ALIASES[required_arch])


def main():
    compose_root, required_arch, check_arch = sys.argv[1], sys.argv[2], sys.argv[3] == '1'
    images = collect_images(compose_root, required_arch)

    daemon = subprocess.run(['docker', 'version'], capture_output=True, text=True)
    if daemon.returncode != 0:
        print('Preflight falló: el daemon de Docker no está disponible en el host')
        return 1

    missing, noarch, ratelimit, failed = [], [], [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        results = pool.map(inspect, images)
        for image, result in zip(images, results):
            if result['status'] == 'missing':
                missing.append(image)
            elif result['status'] == 'ratelimit':
                ratelimit.append(image)
            elif result['status'] == 'ok':
                try:
                    manifest = json.loads(result['stdout'])
                except ValueError:
                    failed.append(f'{image} — salida no JSON')
                    continue
                if check_arch and not has_arch(manifest, required_arch, image):
                    noarch.append(image)
            else:
                failed.append(f'{image} — {result["error"]}')

    if missing or noarch or ratelimit or failed:
        print('Preflight falló: hay imágenes con tag inexistente o sin la arquitectura requerida')
        for image in missing:
            print(f'  - tag inexistente: {image}')
        for image in noarch:
            print(f'  - sin variante {required_arch}: {image}')
        for image in ratelimit:
            print(f'  - rate limit del registry (quota agotada): {image}')
        for entry in failed:
            print(f'  - verificación no concluyente: {entry}')
        if ratelimit:
            print('    La quota anónima de Docker Hub (100 pulls/6h por IP) puede estar agotada; espera a que se renueve o autentica con docker login')
        return 1
    print(f'Preflight OK: {len(images)} imágenes verificadas')
    return 0


if __name__ == '__main__':
    sys.exit(main())
