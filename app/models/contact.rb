# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id                      :bigint           not null, primary key
#  announcements_opted_out :boolean          default(FALSE), not null
#  info_payload            :jsonb
#  last_seen_at            :datetime
#  segments_payload        :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  anonymous_id            :string
#  external_id             :string
#
# Indexes
#
#  index_contacts_on_anonymous_id  (anonymous_id) UNIQUE WHERE (anonymous_id IS NOT NULL)
#  index_contacts_on_external_id   (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#
class Contact < ApplicationRecord
  ## SCOPES
  scope :anonymous, -> { where.not(anonymous_id: nil).where(external_id: nil) }
  scope :identified, -> { where.not(external_id: nil) }
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  ## ASSOCIATIONS
  has_and_belongs_to_many :segment_values
  has_many :segments, -> { distinct }, through: :segment_values
  has_many :announcement_reads, dependent: :destroy
  has_many :ticket_votes, dependent: :destroy
  has_many :voted_tickets, through: :ticket_votes, source: :ticket
  has_many :submitted_tickets, class_name: "Ticket", dependent: :nullify

  ## VALIDATIONS
  validates :external_id, uniqueness: true, allow_nil: true
  validates :anonymous_id, uniqueness: true, allow_nil: true
  validate :must_have_identity
  ## CALLBACKS
  ## OTHER

  def anonymous?
    external_id.blank? && anonymous_id.present?
  end

  def identified?
    external_id.present?
  end

  def to_s
    external_id
  end

  def update_segments_from_payload(segments_data)
    return unless segments_data.is_a?(Hash)

    normalized_segments_data = normalize_hash(segments_data)
    return if normalized_segments_data == normalize_hash(segments_payload)

    transaction do
      self.segments_payload = normalized_segments_data
      segment_values.replace(segment_values_for_payload(normalized_segments_data))
      save!
    end
  end

  private

  def segment_values_for_payload(segments_data)
    segments_by_identifier = Segment.includes(:segment_values)
      .where(identifier: segments_data.keys)
      .index_by(&:identifier)

    segments_data.filter_map do |identifier, value|
      next if value.blank?

      segment = segments_by_identifier[identifier]
      next unless segment

      segment.segment_values.find { |segment_value| segment_value.val == value.to_s } ||
        (segment.allow_new_values? && segment.segment_values.create!(val: value.to_s))
    end
  end

  def normalize_hash(hash)
    return {} unless hash.is_a?(Hash)
    hash.deep_transform_keys { |key| key.to_s.strip.downcase }
  end

  def must_have_identity
    return if external_id.present? || anonymous_id.present?
    errors.add(:base, "must have either external_id or anonymous_id")
  end
end
