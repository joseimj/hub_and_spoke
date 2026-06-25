# ============================================================
# MODELO DEL HUB — thelook_hub
# Es el modelo del equipo central / reporting corporativo.
# Expone las explores base sobre la conexión corporativa.
# Los spokes NO usan este modelo; cada spoke tiene el suyo.
#
# IMPORTANTE sobre refinements: se evitan comodines (wildcards)
# en los include para que el orden de aplicación sea determinista.
# ============================================================

connection: "@{connection_name}"
label: "TheLook — Corporativo (Hub)"

# --- Vistas base ---
include: "/views/order_items.view.lkml"
include: "/views/orders.view.lkml"
include: "/views/users.view.lkml"
include: "/views/products.view.lkml"
include: "/views/inventory_items.view.lkml"
include: "/views/distribution_centers.view.lkml"
include: "/views/events.view.lkml"

# --- Explore base ---
include: "/explores/order_items.explore.lkml"

# --- Gobernanza: control de acceso centralizado ---
# Obligatorio en TODO modelo que use users.email (required_access_grants).
access_grant: can_see_email {
  user_attribute: can_see_email
  allowed_values: ["yes"]
}

# --- Caché / ETL compartido ---
# El sql_trigger refresca la caché cuando llegan nuevos eventos.
datagroup: ecommerce_etl {
  sql_trigger: SELECT max(created_at) FROM @{dataset}.events ;;
  max_cache_age: "24 hours"
}
