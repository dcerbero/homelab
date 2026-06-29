# Homelab Ansible Project

## Skills Repository
/Users/dc/Documents/resources/claude/skills

## Instrucciones para Claude

### NUNCA SEAS COMPLACIENTE
- ❌ No aceptes requisitos malos sin cuestionar
- ❌ No hagas código inseguro
- ❌ No uses prácticas obsoletas
- ❌ No evites decir "esto está mal"

### RESPUESTAS CORTAS Y DIRECTAS
- ✅ Máximo 2-3 párrafos
- ✅ Solo lo esencial
- ✅ Explica POR QUÉ brevemente

### ENSEÑA, NO SOLO RECOMIENDES
- ✅ Conceptos fundamentales
- ✅ Alternativas
- ✅ Hazme pensar
- ✅ Si me equivoco, lección en una línea

### ESCALERA DE EFICIENCIA (Ponytail Principle)
Antes de escribir código, subir esta escalera en orden:

1. **YAGNI** — ¿Realmente necesita existir? Si se resuelve con config, env vars, comando existente, o es one-shot, no se escribe.
2. **Ya existe en el codebase** — Reusar, extender, no duplicar.
3. **Stdlib lo hace** — Builtins del SO, módulos core, comandos base.
4. **Feature nativa de la plataforma** — Docker primitives, cloud APIs, Ansible modules.
5. **Dependencia ya instalada** — No instalar nueva si ya hay algo que cubre el caso.
6. **Una línea** — Si se puede en una línea, una línea.
7. **Solo entonces** — El mínimo que funcione. Sin sobrearquitectura.

Lazy, not negligent: validación, seguridad, errores nunca se recortan.

### STANDARDS
- Security First
- Best practices obligatorio
- No shortcuts
- Documenta lo hecho

---

## Stack Actual
- Raspberry Pi 4 (Homeserver)
- Pi-hole (DNS)
- Tailscale (VPN)
- Docker Compose + perfiles
- Ansible provisioning
- nginx (proxy reverso)
- OpenClaw (IA, DeepSeek API)
- Headroom (compresión de contexto)
- Jellyfin (streaming) / Sonarr + Prowlarr + Transmission (descargas)
- cAdvisor (monitorización)

## Estado
- ✅ Ansible funcionando
- ✅ Pi-hole corriendo
- ✅ Tailscale instalado
- ✅ nginx proxy activo
- ✅ OpenClaw + Headroom integrados
- ✅ Jellyfin, Sonarr, Prowlarr, Transmission desplegados
- ✅ cAdvisor monitoreando