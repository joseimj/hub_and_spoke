# ============================================================
# MANIFEST DEL SPOKE — thelook_marketing
# Importa el HUB. En producción cada proyecto es su propio repo
# de Git, así que usamos remote_dependency apuntando al repo del hub.
# ============================================================

project_name: "thelook_marketing"

# --- Importación REMOTA (producción: repos Git separados) ---
remote_dependency: thelook_hub {
  url: "https://github.com/TU_ORG/thelook_hub"   # <-- cambia por tu repo del hub
  ref: "main"                                    # rama, tag de release o commit SHA

  # Cada spoke puede apuntar a su propio dataset sin tocar el hub:
  # override_constant: dataset { value: "thelook" }
}

# --- Alternativa LOCAL (una sola instancia de Looker, sin repos extra) ---
# Si el hub ya existe como proyecto en la MISMA instancia, comenta el
# bloque remote_dependency de arriba y descomenta esta línea:
# local_dependency: { project: "thelook_hub" }
