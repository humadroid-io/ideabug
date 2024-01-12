# == Schema Information
#
# Table name: tickets
#
#  id             :bigint           not null, primary key
#  classification :integer          default("unclassified")
#  description    :text
#  status         :integer          default("new")
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Ticket < ApplicationRecord
  ## SCOPES
  scope :ordered, -> { order(created_at: :desc) }
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  enum :status, { new: 0, in_progress: 10, completed: 100 }, suffix: true, validate: true, default: :new
  enum :classification, { unclassified: 0, bug: 1, feature_request: 10, task: 100 }, validate: true,
                                                                                     default: :unclassified

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
