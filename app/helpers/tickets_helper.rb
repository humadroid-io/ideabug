module TicketsHelper
  def classification_pill(ticket)
    background_color = case ticket.classification
      when "unclassified" then "fuchsia"
      when "bug" then "red"
      when "feature_request" then "green"
      else "yellow"
    end
    # bg-yellow-600 bg-fuchsia-600 bg-green-600 bg-red-600 hover:bg-yellow-700 hover:bg-fuchsia-700 hover:bg-green-700 hover:bg-red-700 b
    content_tag :span, class: "py-1 px-2 shadow-md no-underline rounded-full bg-#{background_color}-600 text-white text-xs border-#{background_color} btn-primary hover:text-white hover:bg-#{background_color}-700 focus:outline-none active:shadow-none ml-2" do
      ticket.classification.titleize
    end
  end

  def enum_keys_to_option_values(enum)
    enum.keys.map do |k|
      [k.to_s.upcase, k.to_s.titleize]
    end
  end
end
