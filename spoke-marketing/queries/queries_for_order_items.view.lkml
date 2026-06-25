# ============================================================
# REFINEMENTS DEL SPOKE DE MARKETING
# El signo '+' indica que se REFINA la explore base del hub
# (order_items) sin reescribirla. Aquí se añaden consultas
# reutilizables que sirven como "quick starts" y documentación
# viva de las preguntas de negocio del área.
# ============================================================

explore: +order_items {
  query: high_value_geos {
    label: "Estados con mayor margen bruto (90 días)"
    description: "Estados que entregan mayor margen bruto en los últimos 90 días"
    dimensions: [users.state]
    measures: [order_items.total_gross_margin]
    sorts: [order_items.total_gross_margin: desc]
    filters: [
      inventory_items.created_date: "90 days",
      order_items.total_gross_margin: ">=10000",
      users.country: "USA"
    ]
  }

  query: year_over_year {
    label: "Ventas mensuales interanuales"
    description: "Apto para gráfico de líneas comparando ventas mensuales en los últimos 4 años"
    dimensions: [order_items.created_month_name, order_items.created_year]
    pivots: [order_items.created_year]
    measures: [order_items.total_sale_price]
    sorts: [order_items.created_month_name: asc]
    filters: [
      order_items.created_date: "before 0 months ago",
      order_items.created_year: "4 years"
    ]
  }
}
