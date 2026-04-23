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
