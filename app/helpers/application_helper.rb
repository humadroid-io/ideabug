module ApplicationHelper
  include Pagy::Frontend

  def pagy_nav(pagy, id: nil, aria_label: nil, **vars)
    nav_options = {
      id: id,
      class: "join rounded-box border border-base-300 bg-base-100 p-1 shadow-sm",
      aria: {label: aria_label || pagy_t("pagy.aria_label.nav", count: pagy.pages)}
    }.compact

    content_tag(:nav, nav_options) do
      safe_join(
        [
          pagy_prev_link(pagy),
          *pagy_page_links(pagy, **vars),
          pagy_next_link(pagy)
        ].compact
      )
    end
  end

  def avatar_image_tag(user, opts = {})
    image_tag avatar_image_url(user, opts), **opts
  end

  def avatar_image_url(user, opts = {})
    opts = opts.with_indifferent_access
    size = opts.delete(:size) || "50"
    hash = Digest::MD5.hexdigest(user.email_address)

    "https://robohash.org/#{hash}?gravatar=hashed&size=#{size}x#{size}&bgset=bg1"
  end

  def readable_hash(hash)
    hash.map { |k, v| "#{k.split("_").map(&:capitalize).join(" ")}: #{v}" }.join(" - ")
  end

  def nav_link_classes(active: false)
    ["public-nav-link", ("public-nav-link-active" if active)].compact.join(" ")
  end

  def public_nav_link_classes(active: false)
    nav_link_classes(active: active)
  end

  def app_navigation_active?(section)
    case section
    when :overview
      controller_path == "dashboard"
    when :feedback
      controller_path == "tickets" && action_name != "timeline"
    when :roadmap
      controller_path == "tickets" && action_name == "timeline"
    when :announcements
      controller_path == "announcements"
    when :contacts
      controller_path == "contacts"
    when :segments
      controller_path.in?(["segments", "segment_values"])
    else
      false
    end
  end

  def app_navigation_link_classes(active: false)
    ["app-nav-link", ("app-nav-link-active" if active)].compact.join(" ")
  end

  def app_icon(name, class_name: "h-4 w-4")
    paths = {
      overview: '<path d="M4 13h6V4H4v9Zm0 7h6v-4H4v4Zm10 0h6v-9h-6v9Zm0-13h6V4h-6v3Z"></path>',
      feedback: '<path d="M20 15a3 3 0 0 1-3 3H8l-4 3V6a3 3 0 0 1 3-3h10a3 3 0 0 1 3 3v9Z"></path><path d="M8 8h8M8 12h5"></path>',
      roadmap: '<path d="M6 3v18M18 3v18M6 7h12M6 17h12"></path><path d="m10 11 2 2 4-4"></path>',
      announcements: '<path d="M4 13V8l12-4v13L4 13Z"></path><path d="M8 14v4a2 2 0 0 0 2 2h1v-5M16 9h3a2 2 0 0 1 0 4h-3"></path>',
      contacts: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"></path>',
      segments: '<path d="M12 3 2 8l10 5 10-5-10-5Z"></path><path d="m2 12 10 5 10-5M2 16l10 5 10-5"></path>',
      external: '<path d="M15 3h6v6M10 14 21 3"></path><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>',
      plus: '<path d="M12 5v14M5 12h14"></path>',
      arrow: '<path d="M5 12h14m-5-5 5 5-5 5"></path>',
      check: '<path d="m5 12 4 4L19 6"></path>',
      bug: '<path d="M8 2h8M9 2v3m6-3v3M4 13h4m8 0h4M5 7l3 2m11-2-3 2M5 19l3-2m11 2-3-2"></path><rect x="8" y="5" width="8" height="16" rx="4"></rect>',
      idea: '<path d="M9 18h6M10 22h4"></path><path d="M8.5 15.5A7 7 0 1 1 15.5 15.5C14.5 16.2 14 17 14 18h-4c0-1-.5-1.8-1.5-2.5Z"></path>'
    }

    tag.svg(
      paths.fetch(name).html_safe,
      class: class_name,
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.8,
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      aria: {hidden: true}
    )
  end

  def section_header(title:, eyebrow:, meta_items: [], title_class: nil, &block)
    render(
      "shared/section_header",
      title: title,
      eyebrow: eyebrow,
      meta_items: Array(meta_items).compact_blank,
      title_class: title_class,
      actions: (capture(&block) if block_given?)
    )
  end

  def roadmap_ticket_badge_classes(ticket)
    base = "badge badge-outline badge-sm"

    tone = case ticket.classification
    when "bug"
      "badge-error"
    when "task"
      "badge-info"
    else
      "badge-ghost"
    end

    "#{base} #{tone}"
  end

  private

  def pagy_page_links(pagy, **vars)
    pagy.series(**vars).map do |item|
      case item
      when Integer
        link_to pagy.label_for(item), url_for(page: item),
          class: pagy_button_classes
      when String
        content_tag(:span, pagy.label_for(item),
          class: pagy_button_classes(active: true),
          aria: {current: "page"})
      when :gap
        content_tag(:span, pagy_t("pagy.gap"),
          class: pagy_button_classes(disabled: true),
          aria: {hidden: true})
      end
    end
  end

  def pagy_prev_link(pagy)
    if pagy.prev
      link_to "‹", url_for(page: pagy.prev),
        class: pagy_button_classes,
        aria: {label: pagy_t("pagy.aria_label.prev")}
    else
      content_tag(:span, "‹",
        class: pagy_button_classes(disabled: true),
        aria: {disabled: true, label: pagy_t("pagy.aria_label.prev")})
    end
  end

  def pagy_next_link(pagy)
    if pagy.next
      link_to "›", url_for(page: pagy.next),
        class: pagy_button_classes,
        aria: {label: pagy_t("pagy.aria_label.next")}
    else
      content_tag(:span, "›",
        class: pagy_button_classes(disabled: true),
        aria: {disabled: true, label: pagy_t("pagy.aria_label.next")})
    end
  end

  def pagy_button_classes(active: false, disabled: false)
    classes = ["join-item", "btn", "btn-sm", "btn-ghost", "border-0", "min-w-10", "font-medium"]
    classes << "bg-base-200 text-base-content pointer-events-none" if active
    classes << "btn-disabled text-base-content/40" if disabled
    classes.join(" ")
  end
end
