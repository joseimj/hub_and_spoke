view: distribution_centers {
  sql_table_name: @{dataset}.distribution_centers ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: name {
    label: "Centro de distribución"
    type: string
    sql: ${TABLE}.name ;;
  }
  dimension: location {
    type: location
    sql_latitude: ${TABLE}.latitude ;;
    sql_longitude: ${TABLE}.longitude ;;
  }
  measure: count {
    label: "Número de centros"
    type: count
  }
}
