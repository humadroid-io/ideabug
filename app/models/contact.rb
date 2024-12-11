# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id               :bigint           not null, primary key
#  info_payload     :jsonb
#  segments_payload :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  external_id      :string           not null
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
  has_and_belongs_to_many :segment_values
  has_many :segments, -> { distinct }, through: :segment_values

  ## VALIDATIONS
  validates :external_id, presence: true, uniqueness: true
  ## CALLBACKS
  ## OTHER

  def to_s
    external_id
  end

  def update_segments_from_payload(segments_data)
    return unless segments_data.is_a?(Hash)

    normalized_segments_data = normalize_hash(segments_data)
    return if normalized_segments_data == normalize_hash(segments_payload)

    self.segments_payload = normalized_segments_data

    # Process segments only if the payload was changed
    normalized_segments_data.each do |identifier, value|
      segment = Segment.find_by(identifier: identifier.to_s.strip.downcase)
      next unless segment && value.present?

      segment_value = segment.segment_values.find_by(val: value.to_s)

      if segment_value.nil? && segment.allow_new_values?
        segment_value = segment.segment_values.create(val: value.to_s)
      end

      segment_values << segment_value if segment_value && !segment_values.include?(segment_value)
    end

    save
  end

  private

  def normalize_hash(hash)
    return {} unless hash.is_a?(Hash)
    hash.deep_transform_keys { |key| key.to_s.strip.downcase }
  end
end
