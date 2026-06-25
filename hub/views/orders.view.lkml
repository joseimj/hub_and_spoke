view: orders {
  sql_table_name: @{dataset}.orders ;;

  dimension: order_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.order_id ;;
  }
  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }
  dimension: status {
    label: "Estado del pedido"
    type: string
    sql: ${TABLE}.status ;;
  }
  dimension: num_of_item {
    label: "Nº de artículos"
    type: number
    sql: ${TABLE}.num_of_item ;;
  }
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.created_at ;;
  }
  measure: count {
    label: "Número de órdenes"
    type: count
  }
}
