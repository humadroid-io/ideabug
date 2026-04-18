module TicketsHelper
  def classification_pill(ticket)
    badge_tone = case ticket.classification
    when "bug"
      "badge-error"
    when "feature_request"
      "badge-success"
    when "task"
      "badge-warning"
    else
      "badge-ghost"
    end

    content_tag :span, class: "badge badge-outline badge-sm #{badge_tone}" do
      ticket.classification.titleize
    end
  end

  def enum_keys_to_option_values(enum)
    # Rails select helper expects [label, value]. Label = humanized for the
    # user, value = the actual enum key so the model can persist it.
    enum.keys.map { |k| [k.to_s.humanize, k.to_s] }
  end
end
