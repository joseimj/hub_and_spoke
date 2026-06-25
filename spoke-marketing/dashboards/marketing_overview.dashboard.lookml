- dashboard: marketing_overview
  title: "Marketing & Ventas — Visión general"
  description: "Tendencia de ventas interanual y estados de mayor margen. Construido sobre la explore base del hub."
  layout: newspaper
  preferred_viewer: dashboards-next

  filters:
  - name: fecha_pedido
    title: "Fecha de pedido"
    type: field_filter
    default_value: 4 years
    model: thelook_marketing
    explore: order_items
    field: order_items.created_date

  elements:
  - title: "Ventas mensuales interanuales"
    name: ventas_interanuales
    model: thelook_marketing
    explore: order_items
    type: looker_line
    fields: [order_items.created_month_name, order_items.created_year, order_items.total_sale_price]
    pivots: [order_items.created_year]
    sorts: [order_items.created_month_name]
    filters:
      order_items.created_year: 4 years
    listen:
      fecha_pedido: order_items.created_date
    row: 0
    col: 0
    width: 16
    height: 9

  - title: "Margen bruto total (90 días)"
    name: margen_90d
    model: thelook_marketing
    explore: order_items
    type: single_value
    fields: [order_items.total_gross_margin]
    filters:
      order_items.created_date: 90 days
      users.country: USA
    row: 0
    col: 16
    width: 8
    height: 9

  - title: "Top estados por margen bruto (90 días)"
    name: top_estados_margen
    model: thelook_marketing
    explore: order_items
    type: looker_column
    fields: [users.state, order_items.total_gross_margin]
    sorts: [order_items.total_gross_margin desc]
    limit: 15
    filters:
      users.country: USA
      inventory_items.created_date: 90 days
    row: 9
    col: 0
    width: 24
    height: 9
