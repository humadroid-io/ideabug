# frozen_string_literal: true

# == Schema Information
#
# Table name: segment_values
#
#  id         :bigint           not null, primary key
#  val        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  segment_id :bigint           not null
#
# Indexes
#
#  index_segment_values_on_segment_id  (segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (segment_id => segments.id) ON DELETE => cascade
#
class SegmentValue < ApplicationRecord
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  attr_accessor :fallback_id

  ## ASSOCIATIONS
  belongs_to :segment

  ## VALIDATIONS
  validates :val, presence: true, uniqueness: { scope: :segment_id }
  ## CALLBACKS
  ## OTHER

  private

  ## callback methods
end
