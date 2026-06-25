view: products {
  sql_table_name: @{dataset}.products ;;

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  # Los queries del cliente referencian products.item_name
  dimension: item_name {
    label: "Nombre del producto"
    type: string
    sql: ${TABLE}.name ;;
  }
  dimension: category {
    label: "Categoría"
    type: string
    sql: ${TABLE}.category ;;
  }
  dimension: brand {
    label: "Marca"
    type: string
    sql: ${TABLE}.brand ;;
  }
  dimension: department {
    label: "Departamento"
    type: string
    sql: ${TABLE}.department ;;
  }
  dimension: sku {
    type: string
    sql: ${TABLE}.sku ;;
  }
  dimension: distribution_center_id {
    type: number
    hidden: yes
    sql: ${TABLE}.distribution_center_id ;;
  }
  dimension: cost {
    label: "Coste"
    type: number
    value_format_name: usd
    sql: ${TABLE}.cost ;;
  }
  dimension: retail_price {
    label: "Precio de catálogo"
    type: number
    value_format_name: usd
    sql: ${TABLE}.retail_price ;;
  }

  measure: count {
    label: "Número de productos"
    type: count
  }
}
