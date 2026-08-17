module ApplicationHelper
  ESTADO_LABELS = {
    "pendiente_pago" => "Pendiente pago",
    "pagado"         => "Pagado",
    "en_preparacion" => "En preparación",
    "despachado"     => "Despachado",
    "entregado"      => "Entregado",
    "cancelado"      => "Cancelado"
  }.freeze

  CATEGORIA_LABELS = {
    "ahumado" => "Ahumado"
  }.freeze

  SIGUIENTE_ACCION_LABEL = {
    "pendiente_pago" => "Confirmar pago recibido",
    "pagado"         => "Marcar en preparación",
    "en_preparacion" => "Marcar como despachado",
    "despachado"     => "Marcar como entregado"
  }.freeze

  def estado_label(estado)
    ESTADO_LABELS[estado.to_s] || estado.to_s.humanize
  end

  def siguiente_accion_label(estado)
    SIGUIENTE_ACCION_LABEL[estado.to_s]
  end

  def estado_badge(estado)
    content_tag(:span, estado_label(estado), class: "badge badge-#{estado}")
  end

  def categoria_label(categoria)
    CATEGORIA_LABELS[categoria.to_s] || categoria.to_s.humanize
  end

  def formato_pesos(monto)
    number_to_currency(monto, unit: "$", separator: ",", delimiter: ".", precision: 0)
  end

  alias numero_a_pesos formato_pesos
end
