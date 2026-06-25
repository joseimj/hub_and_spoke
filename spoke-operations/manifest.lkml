# ============================================================
# MANIFEST DEL SPOKE — thelook_operations
# Mismo patrón que el spoke de marketing: importa el HUB.
# ============================================================

project_name: "thelook_operations"

# --- Importación REMOTA (producción: repos Git separados) ---
remote_dependency: thelook_hub {
  url: "https://github.com/TU_ORG/thelook_hub"   # <-- cambia por tu repo del hub
  ref: "main"

  # override_constant: dataset { value: "thelook" }
}

# --- Alternativa LOCAL (misma instancia de Looker) ---
# local_dependency: { project: "thelook_hub" }
