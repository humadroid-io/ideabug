module ApplicationHelper
  include Pagy::Frontend

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
end
