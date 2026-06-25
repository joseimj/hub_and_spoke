# ============================================================
# MANIFEST DEL HUB — thelook_hub
# Define el nombre del proyecto y las CONSTANTES que los spokes
# pueden sobreescribir (override_constant) para apuntar a su
# propia conexión / dataset SIN tocar el código del hub.
# ============================================================

project_name: "thelook_hub"

# Conexión usada por el modelo PROPIO del hub (reporting corporativo).
# Los spokes definen su conexión directamente en su modelo.
constant: connection_name {
  value: "looker-private-demo"
  export: override_optional
}

# Dataset/esquema. Lo usan las VISTAS del hub (sql_table_name) y el
# datagroup. Como las vistas son archivos importados, un spoke puede
# cambiar este valor con override_constant en su propio manifest.
constant: dataset {
  value: "thelook"
  export: override_optional
}
