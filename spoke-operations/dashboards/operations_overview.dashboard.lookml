- dashboard: operations_overview
  title: "Operaciones — Pipeline y stock"
  description: "Estado de envíos, antigüedad de inventario y pedidos retrasados. Construido sobre la explore base del hub."
  layout: newspaper
  preferred_viewer: dashboards-next

  filters:
  - name: centro
    title: "Centro de distribución"
    type: field_filter
    default_value: Chicago IL
    model: thelook_operations
    explore: order_items
    field: distribution_centers.name

  elements:
  - title: "Estado del pipeline de envíos (60 días)"
    name: pipeline_envios
    model: thelook_operations
    explore: order_items
    type: looker_column
    fields: [order_items.created_date, order_items.status, order_items.order_count]
    pivots: [order_items.status]
    sorts: [order_items.created_date]
    filters:
      order_items.created_date: 60 days
      order_items.status: "Complete,Shipped,Processing"
    listen:
      centro: distribution_centers.name
    row: 0
    col: 0
    width: 16
    height: 9

  - title: "Antigüedad del inventario"
    name: antiguedad_inventario
    model: thelook_operations
    explore: order_items
    type: looker_column
    fields: [inventory_items.days_in_inventory_tier, inventory_items.count]
    sorts: [inventory_items.days_in_inventory_tier]
    listen:
      centro: distribution_centers.name
    row: 0
    col: 16
    width: 8
    height: 9

  - title: "Pedidos severamente retrasados (>3 días en Processing)"
    name: pedidos_retrasados
    model: thelook_operations
    explore: order_items
    type: looker_grid
    fields: [order_items.order_id, order_items.created_date, products.item_name, users.email, order_items.average_days_to_process]
    sorts: [order_items.average_days_to_process desc]
    limit: 100
    filters:
      order_items.created_date: before 3 days ago
      order_items.status: Processing
    listen:
      centro: distribution_centers.name
    row: 9
    col: 0
    width: 24
    height: 9
