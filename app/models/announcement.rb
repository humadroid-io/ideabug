# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id           :bigint           not null, primary key
#  preview      :text
#  published_at :datetime         not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_announcements_on_published_at  (published_at)
#
class Announcement < ApplicationRecord
  ## SCOPES
  scope :published, -> { where("published_at <= ?", Time.current) }
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  has_rich_text :content
  ## ASSOCIATIONS
  has_many :announcement_reads, dependent: false
  has_and_belongs_to_many :segment_values
  has_many :segments, -> { distinct }, through: :segment_values
  ## VALIDATIONS
  validates :title, presence: true
  ## CALLBACKS
  ## OTHER

  def self.visible_to_contact(contact)
    contact_id = contact.is_a?(Contact) ? contact.id : contact

    where(id: visibility_relation_for(contact_id))
  end

  def self.read_state_select_for(contact, unread_cutoff:)
    contact_id = contact.is_a?(Contact) ? contact.id : contact
    quoted_cutoff = connection.quote(unread_cutoff)

    <<~SQL.squish
      announcements.*,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM announcement_reads
          WHERE announcement_reads.announcement_id = announcements.id
            AND announcement_reads.contact_id = #{contact_id.to_i}
        ) THEN 1
        WHEN announcements.published_at > #{quoted_cutoff} THEN 0
        ELSE 1
      END AS read
    SQL
  end

  def to_s
    title
  end

  def read(contact = Current.contact)
    if attributes.key?("read")
      return ActiveModel::Type::Boolean.new.cast(attributes["read"])
    end
    return @read unless @read.nil?
    @read = (contact && @read = announcement_reads.exists?(contact: contact)) || false
  end

  private

  def self.visibility_relation_for(contact_id)
    left_joins(:segment_values)
      .group("announcements.id")
      .having(
        <<~SQL.squish
          COUNT(DISTINCT segment_values.segment_id) = 0
          OR COUNT(
            DISTINCT CASE
              WHEN segment_values.id IN (
                SELECT segment_value_id
                FROM contacts_segment_values
                WHERE contact_id = #{contact_id.to_i}
              ) THEN segment_values.segment_id
            END
          ) = COUNT(DISTINCT segment_values.segment_id)
        SQL
      )
      .select(:id)
  end
  private_class_method :visibility_relation_for

  ## callback methods
end
