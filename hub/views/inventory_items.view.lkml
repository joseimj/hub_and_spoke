view: inventory_items {
  sql_table_name: @{dataset}.inventory_items ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: product_id {
    type: number
    hidden: yes
    sql: ${TABLE}.product_id ;;
  }
  dimension: cost {
    label: "Coste"
    type: number
    value_format_name: usd
    sql: ${TABLE}.cost ;;
  }
  dimension_group: created {
    label: "Entrada en inventario"
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.created_at ;;
  }
  dimension_group: sold {
    label: "Venta"
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.sold_at ;;
  }

  # Días en inventario: de la entrada hasta la venta (o hasta hoy si sigue en stock).
  # NOTA: dialecto BigQuery (timestamp_diff / current_timestamp).
  dimension: days_in_inventory {
    type: number
    sql: timestamp_diff(coalesce(${sold_raw}, current_timestamp()), ${created_raw}, day) ;;
  }
  dimension: days_in_inventory_tier {
    label: "Antigüedad de stock (tramos)"
    type: tier
    tiers: [0, 5, 10, 20, 40, 80]
    style: integer
    sql: ${days_in_inventory} ;;
  }
  dimension: is_sold {
    label: "¿Vendido?"
    type: yesno
    sql: ${sold_raw} is not null ;;
  }

  measure: count {
    label: "Artículos en inventario"
    type: count
  }
  measure: total_cost {
    label: "Coste total de inventario"
    type: sum
    value_format_name: usd
    sql: ${cost} ;;
  }
}
