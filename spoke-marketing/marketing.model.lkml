# ============================================================
# MODELO SPOKE — MARKETING & VENTAS
# Importa las vistas y la explore base del hub, las refina con
# consultas propias del área y construye su dashboard.
# El '//thelook_hub/...' referencia archivos del proyecto importado.
# ============================================================

connection: "looker-private-demo"   # <-- conexión propia del spoke
label: "Marketing & Ventas"

# 1) Vistas del hub (proyecto importado)
include: "//thelook_hub/views/order_items.view.lkml"
include: "//thelook_hub/views/orders.view.lkml"
include: "//thelook_hub/views/users.view.lkml"
include: "//thelook_hub/views/products.view.lkml"
include: "//thelook_hub/views/inventory_items.view.lkml"
include: "//thelook_hub/views/distribution_centers.view.lkml"

# 2) Explore BASE del hub  (DEBE ir ANTES del refinement)
include: "//thelook_hub/explores/order_items.explore.lkml"

# 3) Refinements + consultas propias del spoke (DESPUÉS de la base)
include: "/queries/queries_for_order_items.view.lkml"

# 4) Dashboards LookML del área
include: "/dashboards/*.dashboard.lookml"

# Gobernanza: obligatorio porque users.email usa required_access_grants.
# El grant se declara en cada modelo; la regla a nivel de campo vive en el hub.
access_grant: can_see_email {
  user_attribute: can_see_email
  allowed_values: ["yes"]
}

# Caché/ETL: mismo nombre de datagroup que en el hub (lo exige persist_with).
# Las constantes del hub no son visibles aquí, por eso fijamos el esquema.
datagroup: ecommerce_etl {
  sql_trigger: SELECT max(created_at) FROM thelook.events ;;
  max_cache_age: "24 hours"
}
