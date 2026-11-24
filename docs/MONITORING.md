# 📊 Métricas — Prometheus + Grafana (en pausa)

Las métricas del homelab viajaban por Tailscale hasta un monitor central en la nube. Hoy ese backend **no está desplegado**: el stack se retiró de [talos](HARDWARE.md#talos) para dejar la VM solo con el failover de Pi-hole, y la configuración espera en el repo a que se le asigne una máquina nueva. Los exporters siguen corriendo, pero nadie los consume.

## Índice

- [Estado actual](#estado-actual)
- [Qué sigue corriendo](#qué-sigue-corriendo)
- [Qué se retiró](#qué-se-retiró)
- [Por qué se pausó](#por-qué-se-pausó)
- [Cómo reactivarlo](#cómo-reactivarlo)
- [Limpieza pendiente en talos](#limpieza-pendiente-en-talos)
- [Historial](#historial)

## Estado actual

- **Prometheus y Grafana no se despliegan en ninguna máquina** desde el 2026-11-23.
- El rol `monitoring` (`ansible/roles/monitoring/`) y los servicios `services/docker/prometheus/` y `services/docker/grafana/` **siguen en el repo**, intactos y sin invocación. Ningún play los llama.
- El perfil `metrics` de `compose.yaml` sigue existiendo, pero está huérfano: `docker compose --profile metrics up` solo tendría sentido tras reasignar el rol.
- Consecuencia inmediata: **no hay dashboard ni histórico**, y [talos](HARDWARE.md#talos) ya no aparece como instancia porque sus exporters eran internos del propio host.

## Qué sigue corriendo

Los roles `cadvisor` ([yoda](HARDWARE.md#yoda) y [anton](HARDWARE.md#anton)) y `smartctl` ([anton](HARDWARE.md#anton)) no se tocaron:

| Exporter | Máquina | Puerto | Perfil |
|---|---|---|---|
| node-exporter | yoda, anton | 9100 | `monitoring` |
| cAdvisor | yoda, anton | 9101 | `monitoring` |
| smartctl-exporter | anton | 9633 | `smart` |

Están accesibles por LAN/Tailscale y responden en `/metrics`, pero **no hay Prometheus que los scrapee**. Mantenerlos cuesta poca RAM y deja el terreno listo para reactivar.

## Qué se retiró

- El rol `monitoring` del play de talos (`ansible/playbook.yml`), junto con sus tags `monitoring`/`metrics` en el rol `preflight` de ese play.
- Los contenedores de Prometheus, Grafana, node-exporter y cAdvisor de talos (teardown manual, ver [Limpieza pendiente](#limpieza-pendiente-en-talos)).
- El puerto `3000` (Grafana) de la tabla de puertos expuestos.

## Por qué se pausó

[`talos`](HARDWARE.md#talos) pasó a tener un único propósito: **DNS de failover**. Mantener ahí Prometheus + Grafana + 2 exporters consumía RAM y superficie de ataque en una VM que solo necesita Pi-hole y Tailscale. La decisión fue quitar el rol y dejar el stack disponible para reubicarlo donde tenga sentido (candidato natural: [anton](HARDWARE.md#anton), 7.7 GiB y x86_64; [yoda](HARDWARE.md#yoda) queda descartado por sus 3.7 GiB compartidos con Pi-hole, nginx y Heimdall).

## Cómo reactivarlo

1. **Elegir host** y añadir el rol a su play en `ansible/playbook.yml`:
   ```yaml
   - role: monitoring
     tags: [monitoring, metrics, <host>]
   ```
   Y añadir `monitoring`/`metrics` a la lista de tags de `preflight` de ese play (regla de mantenimiento documentada en [`ANSIBLE.md`](ANSIBLE.md#preflight-validación-de-imágenes)).

2. **Reescribir `services/docker/prometheus/config/prometheus.yml`**. Los targets de talos (`svcNodeExporter:9100`, `svccAdvisor:8080`) eran nombres internos del compose de esa VM y ya no existen. Dos caminos:
   - **Sin métricas de talos** (coherente con el objetivo): borrar sus targets y sus `relabel_configs`.
   - **Con métricas de talos**: volver a desplegar node-exporter y cAdvisor ahí (contradice el propósito de la VM) o apuntar a `talos:9100`/`talos:9101` por Tailscale — lo que exige que esos puertos estén publicados y los contenedores corriendo.

3. **Ajustar la config de scrape del nuevo host**: si Prometheus corre en anton, los targets `yoda:*` y `anton:*` vía Tailscale siguen siendo válidos; el `localhost:9090` del job `prometheus` también.

4. **Definir `GRAFANA_ADMIN_PASSWORD`** en `ansible/.env` (sigue documentado en [`ANSIBLE.md`](ANSIBLE.md#variables-de-entorno)) y verificar que `run.sh` la pasa.

5. **Desplegar**:
   ```bash
   cd ansible/
   bash run.sh <host> --tags monitoring,metrics
   ```

6. **Verificar** (en el host del stack):
   ```bash
   docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets
   # esperado: targets up = self + node-exporter/cAdvisor de yoda y anton + smartctl de anton
   # (+ los de talos solo si se reañadieron)
   ```

7. **Grafana**: `http://<ip-host>:3000`, usuario `admin`, password de `GRAFANA_ADMIN_PASSWORD`. El dashboard sale del seed `services/docker/grafana/seed/homelab.json`, que el rol copia a `$PATH_DATA/persistence/grafana/dashboards/` en cada deploy. La variable **Host** (`instance`) filtra por máquina.

## Limpieza pendiente en talos

Quitar el rol no apaga contenedores ya creados. Si aún no se hizo, en talos:

```bash
cd ~/services/homelab/services/docker
docker compose --profile monitoring --profile metrics down
docker ps --format '{{.Names}}'   # solo debe quedar pihole
```

Los datos en `/server/persistence/{prometheus,grafana}` son restos del stack: se pueden conservar (por si se reutiliza el histórico) o borrar una vez decido el nuevo host. No afectan a Pi-hole.

## Historial

- [x] **Paso 1 — talos**: stack completo (Prometheus, Grafana, node-exporter, cAdvisor) desplegado y funcional.
- [x] **Paso 2 — yoda**: cAdvisor (`9101:8080`) y node-exporter (`9100`) desplegados y verificados.
- [x] **Paso 3 — talos**: targets de yoda añadidos a `prometheus.yml`; dashboard unificado con agrupación por instancia.
- [x] **Paso 4 — anton**: node-exporter (`9100`), cAdvisor (`9101`) y smartctl-exporter (`9633`) desplegados; targets de anton en `prometheus.yml`. Llegó a haber **8 targets up**.
- [x] **Paso 5 — 2026-11-23**: talos queda solo con Pi-hole y Tailscale; el rol `monitoring` sale de su play y el stack pasa a **en pausa**.

## Próximos pasos opcionales

> [!TIP]
> Ideas para cuando el stack vuelva a estar desplegado — ninguna urgente.

- Reubicar Prometheus + Grafana en [anton](HARDWARE.md#anton) y reescribir los targets de talos.
- Alertas (Grafana alerting + notificaciones a ntfy/Telegram).
- Dashboard de Pi-hole en Grafana (`alantoch/pihole-exporter`).
- Recolecta de logs centralizados (Loki + Promtail).
