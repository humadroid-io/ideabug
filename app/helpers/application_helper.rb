module ApplicationHelper
  def avatar_image_tag(user, opts = {})
    image_tag avatar_image_url(user, opts), **opts
  end

  def avatar_image_url(user, opts = {})
    opts = opts.with_indifferent_access
    size = opts.delete(:size) || "50"
    hash = Digest::MD5.hexdigest(user.email_address)

    "https://robohash.org/#{hash}?gravatar=hashed&size=#{size}x#{size}&bgset=bg1"
  end
end
