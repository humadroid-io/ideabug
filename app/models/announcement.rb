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

  def to_s
    title
  end

  def read(contact = Current.contact)
    return attributes["read"] if attributes.key?("read")
    return @read unless @read.nil?
    @read = (contact && @read = announcement_reads.exists?(contact: contact)) || false
  end

  private

  ## callback methods
end
