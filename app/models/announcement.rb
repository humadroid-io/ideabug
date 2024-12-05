# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id         :bigint           not null, primary key
#  preview    :text
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Announcement < ApplicationRecord
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  has_rich_text :content
  ## ASSOCIATIONS
  ## VALIDATIONS
  validates :title, presence: true
  ## CALLBACKS
  ## OTHER

  def to_s
    title
  end

  private

  ## callback methods
end
