# ============================================================
# VISTA BASE (HUB) — order_items
# Definición central y reutilizable. NO se edita en los spokes;
# los spokes la importan y la refinan con `view: +order_items`.
# El esquema/dataset se parametriza con la constante @{dataset}.
# ============================================================

view: order_items {
  sql_table_name: @{dataset}.order_items ;;

  # --- Claves primarias y de unión ---
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }
  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }
  dimension: product_id {
    type: number
    hidden: yes
    sql: ${TABLE}.product_id ;;
  }
  dimension: inventory_item_id {
    type: number
    hidden: yes
    sql: ${TABLE}.inventory_item_id ;;
  }

  # --- Estado y fechas ---
  dimension: status {
    label: "Estado"
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension_group: created {
    label: "Fecha de pedido"
    type: time
    timeframes: [raw, time, date, week, month, month_name, quarter, year]
    sql: ${TABLE}.created_at ;;
  }
  dimension_group: shipped {
    type: time
    timeframes: [raw, date, week, month]
    sql: ${TABLE}.shipped_at ;;
  }
  dimension_group: delivered {
    type: time
    timeframes: [raw, date]
    sql: ${TABLE}.delivered_at ;;
  }

  # Días en procesar (de "created" a "shipped"). NOTA: dialecto BigQuery.
  dimension: days_to_process {
    type: number
    sql: timestamp_diff(${shipped_raw}, ${created_raw}, hour) / 24.0 ;;
  }

  # --- Importes ---
  dimension: sale_price {
    label: "Precio de venta"
    type: number
    value_format_name: usd
    sql: ${TABLE}.sale_price ;;
  }

  # Margen bruto por línea = precio de venta - coste del inventario (join 1:1)
  dimension: gross_margin {
    label: "Margen bruto (línea)"
    type: number
    value_format_name: usd
    sql: ${sale_price} - ${inventory_items.cost} ;;
  }

  # --- Medidas ---
  measure: order_count {
    label: "Número de pedidos"
    type: count_distinct
    sql: ${order_id} ;;
    drill_fields: [order_id, status, created_date, total_sale_price]
  }
  measure: total_sale_price {
    label: "Ventas totales"
    type: sum
    value_format_name: usd
    sql: ${sale_price} ;;
  }
  measure: total_gross_margin {
    label: "Margen bruto total"
    type: sum
    value_format_name: usd
    sql: ${gross_margin} ;;
  }
  measure: average_days_to_process {
    label: "Días promedio en procesar"
    type: average
    value_format_name: decimal_1
    sql: ${days_to_process} ;;
  }
}
