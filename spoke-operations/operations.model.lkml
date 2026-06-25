# ============================================================
# MODELO SPOKE — OPERACIONES / SUPPLY CHAIN
# Importa el hub y añade las consultas operativas (pipeline de
# envíos, antigüedad de inventario y pedidos severamente retrasados).
# ============================================================

connection: "looker-private-demo"   # <-- conexión propia del spoke
label: "Operaciones & Supply Chain"

# 1) Vistas del hub
include: "//thelook_hub/views/order_items.view.lkml"
include: "//thelook_hub/views/orders.view.lkml"
include: "//thelook_hub/views/users.view.lkml"
include: "//thelook_hub/views/products.view.lkml"
include: "//thelook_hub/views/inventory_items.view.lkml"
include: "//thelook_hub/views/distribution_centers.view.lkml"

# 2) Explore BASE del hub (ANTES del refinement)
include: "//thelook_hub/explores/order_items.explore.lkml"

# 3) Refinements + consultas del área (DESPUÉS de la base)
include: "/queries/queries_for_order_items.view.lkml"

# 4) Dashboards LookML del área
include: "/dashboards/*.dashboard.lookml"

# Gobernanza (el reporte de pedidos retrasados usa users.email).
access_grant: can_see_email {
  user_attribute: can_see_email
  allowed_values: ["yes"]
}

datagroup: ecommerce_etl {
  sql_trigger: SELECT max(created_at) FROM thelook.events ;;
  max_cache_age: "24 hours"
}
