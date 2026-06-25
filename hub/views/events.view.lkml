# Vista mínima de eventos. Se usa como base para el datagroup (sql_trigger)
# y queda disponible para análisis de comportamiento si se necesita.
view: events {
  sql_table_name: @{dataset}.events ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }
  dimension: event_type {
    label: "Tipo de evento"
    type: string
    sql: ${TABLE}.event_type ;;
  }
  dimension: traffic_source {
    label: "Fuente de tráfico"
    type: string
    sql: ${TABLE}.traffic_source ;;
  }
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.created_at ;;
  }
  measure: count {
    label: "Número de eventos"
    type: count
  }
}
