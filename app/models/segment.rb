# frozen_string_literal: true

# == Schema Information
#
# Table name: segments
#
#  id               :bigint           not null, primary key
#  allow_new_values :boolean          default(FALSE)
#  identifier       :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_segments_on_identifier  (identifier) UNIQUE
#
class Segment < ApplicationRecord
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  normalizes :identifier, with: ->(identifier) { identifier.strip.downcase }
  ## ASSOCIATIONS
  has_many :segment_values, dependent: false
  ## VALIDATIONS
  validates :identifier, presence: true, uniqueness: true
  ## CALLBACKS
  ## OTHER
  accepts_nested_attributes_for :segment_values, allow_destroy: true

  def to_s
    identifier
  end

  private

  ## callback methods
end
