# ============================================================
# EXPLORE BASE (HUB) — order_items
# Definición central de la explore y sus joins. Los spokes la
# IMPORTAN (include "//thelook_hub/explores/...") y la REFINAN
# con `explore: +order_items { ... }` para añadir sus consultas.
#
# Aquí NO se define la conexión: la conexión vive en cada modelo.
# La política de caché se comparte vía el datagroup `ecommerce_etl`.
# ============================================================

explore: order_items {
  label: "Order Items (base del hub)"
  description: "Líneas de pedido con clientes, productos, inventario y centros de distribución. Definición gobernada en el hub."

  persist_with: ecommerce_etl

  join: orders {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.order_id} = ${orders.order_id} ;;
  }
  join: users {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.user_id} = ${users.id} ;;
  }
  join: inventory_items {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
  }
  join: products {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.product_id} = ${products.id} ;;
  }
  join: distribution_centers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
  }
}
