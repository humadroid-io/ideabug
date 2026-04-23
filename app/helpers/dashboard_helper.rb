module DashboardHelper
  def sparkline_svg(values, width: 320, height: 48)
    return content_tag(:span, "—", class: "text-base-content/50") if values.empty?

    max = values.max.to_f
    max = 1.0 if max.zero?
    step = (values.size > 1) ? width.to_f / (values.size - 1) : 0
    points = values.each_with_index.map { |v, i|
      x = (i * step).round(1)
      y = (height - (v / max) * (height - 4) - 2).round(1)
      "#{x},#{y}"
    }.join(" ")

    content_tag(:svg, viewBox: "0 0 #{width} #{height}", width: width, height: height, class: "block") do
      tag.polyline(points: points, fill: "none", stroke: "currentColor", "stroke-width": 2, "stroke-linejoin": "round")
    end
  end
end
