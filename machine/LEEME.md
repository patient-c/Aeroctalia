# Archivos atados a una máquina

install.sh copia esto **solo si el destino no existe** y **nunca copia las
plantillas** (`.plantilla`), que son solo de referencia.

- `etc/*.plantilla` → fstab, crypttab, hostname, hosts. Plantillas con
  placeholders: los valores reales (UUID de tus particiones, nombre de tu
  máquina) no se publican. Y en una Arch recién instalada ya existen, así que
  casi nunca se usan.
- `home/.config/hypr/monitors.conf` → tus monitores (esto sí va real, son solo
  nombres de salida y resoluciones). Si no coincide con los tuyos, corregilo o
  regeneralo con `nwg-displays`.

## English

# Machine-specific files

`install.sh` copies these files **only if the destination does not exist**. It
**never copies** `.plantilla` files; those are reference templates only.

- `etc/*.plantilla` → fstab, crypttab, hostname and hosts. These templates use
  placeholders; real values (partition UUIDs and machine name) are not
  published. A fresh Arch installation already has these files, so they are
  rarely needed.
- `home/.config/hypr/monitors.conf` → monitor outputs (this file contains real
  output names and resolutions). If they do not match your displays, edit the
  file or regenerate it with `nwg-displays`.
