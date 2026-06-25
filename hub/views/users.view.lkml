view: users {
  sql_table_name: @{dataset}.users ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: first_name {
    label: "Nombre"
    type: string
    sql: ${TABLE}.first_name ;;
  }
  dimension: last_name {
    label: "Apellido"
    type: string
    sql: ${TABLE}.last_name ;;
  }

  # --- Campo gobernado de forma CENTRAL por el hub ---
  # Solo se muestra a usuarios con el user_attribute can_see_email = "yes".
  # El access_grant referido aquí se declara en cada modelo que use la vista.
  dimension: email {
    label: "Email"
    type: string
    sql: ${TABLE}.email ;;
    required_access_grants: [can_see_email]
  }

  dimension: age {
    label: "Edad"
    type: number
    sql: ${TABLE}.age ;;
  }
  dimension: gender {
    label: "Género"
    type: string
    sql: ${TABLE}.gender ;;
  }
  dimension: state {
    label: "Estado/Provincia"
    type: string
    sql: ${TABLE}.state ;;
  }
  dimension: city {
    label: "Ciudad"
    type: string
    sql: ${TABLE}.city ;;
  }
  dimension: country {
    label: "País"
    type: string
    sql: ${TABLE}.country ;;
  }
  dimension: traffic_source {
    label: "Fuente de tráfico"
    type: string
    sql: ${TABLE}.traffic_source ;;
  }
  dimension: location {
    type: location
    sql_latitude: ${TABLE}.latitude ;;
    sql_longitude: ${TABLE}.longitude ;;
  }
  dimension_group: created {
    label: "Fecha de alta"
    type: time
    timeframes: [raw, date, week, month, year]
    sql: ${TABLE}.created_at ;;
  }

  measure: count {
    label: "Número de clientes"
    type: count
    drill_fields: [id, first_name, last_name, state]
  }
}
