#!/usr/bin/env python3
import concurrent.futures
import json
import pathlib
import re
import subprocess
import sys

IMAGE_RE = re.compile(r'^\s*image:\s*(\S+)')
ARCH_ALIASES = {
    'arm64': ('arm64', 'arm64v8', 'aarch64'),
    'amd64': ('amd64', 'x86_64'),
}


def collect_images(compose_root):
    images = set()
    for compose in pathlib.Path(compose_root).rglob('compose.yaml'):
        for line in compose.read_text(errors='replace').splitlines():
            match = IMAGE_RE.match(line)
            if match:
                images.add(match.group(1))
    return sorted(images)


def manifest_json(image):
    result = subprocess.run(
        ['docker', 'manifest', 'inspect', image],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    try:
        return json.loads(result.stdout)
    except ValueError:
        return None


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
    images = collect_images(compose_root)

    daemon = subprocess.run(['docker', 'version'], capture_output=True, text=True)
    if daemon.returncode != 0:
        print('Preflight falló: el daemon de Docker no está disponible en el host')
        return 1

    missing, noarch = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        manifests = pool.map(manifest_json, images)
        for image, manifest in zip(images, manifests):
            if manifest is None:
                missing.append(image)
            elif check_arch and not has_arch(manifest, required_arch, image):
                noarch.append(image)

    if missing or noarch:
        print('Preflight falló: hay imágenes con tag inexistente o sin la arquitectura requerida')
        for image in missing:
            print(f'  - tag inexistente: {image}')
        for image in noarch:
            print(f'  - sin variante {required_arch}: {image}')
        return 1
    print(f'Preflight OK: {len(images)} imágenes verificadas')
    return 0


if __name__ == '__main__':
    sys.exit(main())
