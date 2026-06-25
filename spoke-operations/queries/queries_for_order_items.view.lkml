# ============================================================
# REFINEMENTS DEL SPOKE DE OPERACIONES
# Refina la explore base del hub (order_items) con las consultas
# operativas del área de logística / supply chain.
# ============================================================

explore: +order_items {
  query: shipments_status {
    label: "Estado del pipeline de envíos"
    description: "Resume el estado del pipeline de envíos por día"
    dimensions: [order_items.created_date, order_items.status]
    pivots: [order_items.status]
    measures: [order_items.order_count]
    filters: [
      distribution_centers.name: "Chicago IL",
      order_items.created_date: "60 days",
      order_items.status: "Complete,Shipped,Processing"
    ]
  }

  query: inventory_aging {
    label: "Antigüedad del inventario"
    description: "Volumen de inventario por antigüedad del artículo en stock"
    dimensions: [inventory_items.days_in_inventory_tier]
    measures: [inventory_items.count]
    filters: [distribution_centers.name: "Chicago IL"]
    # timezone: "America/Los_Angeles"
  }

  query: severely_delayed_orders {
    label: "Pedidos severamente retrasados"
    description: "Pedidos que siguen en 'Processing' después de 3 días, filtrados por centro de distribución"
    dimensions: [
      order_items.created_date,
      order_items.order_id,
      products.item_name,
      order_items.status,
      users.email
    ]
    measures: [order_items.average_days_to_process]
    filters: [
      distribution_centers.name: "Chicago IL",
      order_items.created_date: "before 3 days ago",
      order_items.status: "Processing"
    ]
  }
}
