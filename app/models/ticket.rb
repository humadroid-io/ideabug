class Ticket < ApplicationRecord
  ## SCOPES
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

  private

  def to_s
    title
  end

  ## callback methods
end
