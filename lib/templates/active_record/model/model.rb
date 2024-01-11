<% module_namespacing do -%>
# frozen_string_literal: true

class <%= class_name %> < <%= parent_class_name.classify %>
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
<% if attributes.any?(&:password_digest?) -%>
  has_secure_password
<% end -%>
  ## ASSOCIATIONS
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %>
<% end -%>
  ## VALIDATIONS
  ## CALLBACKS
  ## OTHER

  private

  ## callback methods
end

<% end -%>
