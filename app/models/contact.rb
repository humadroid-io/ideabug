# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  info_payload :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#
# Indexes
#
#  index_contacts_on_external_id  (external_id) UNIQUE
#
class Contact < ApplicationRecord
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  ## ASSOCIATIONS
  ## VALIDATIONS
  validates :external_id, presence: true, uniqueness: true
  ## CALLBACKS
  ## OTHER

  def to_s
    external_id
  end

  private

  ## callback methods
end
