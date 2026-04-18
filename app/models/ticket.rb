# == Schema Information
#
# Table name: tickets
#
#  id                :bigint           not null, primary key
#  classification    :integer          default("unclassified")
#  context           :jsonb
#  description       :text
#  public_on_roadmap :boolean          default(FALSE), not null
#  scheduled_for     :datetime
#  shipped_at        :datetime
#  source            :string           default("admin"), not null
#  status            :integer          default("new")
#  title             :string
#  votes_count       :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  contact_id        :bigint
#
# Indexes
#
#  index_tickets_on_classification_and_status             (classification,status)
#  index_tickets_on_contact_id                            (contact_id)
#  index_tickets_on_public_on_roadmap_and_classification  (public_on_roadmap,classification)
#  index_tickets_on_scheduled_for                         (scheduled_for)
#  index_tickets_on_shipped_at                            (shipped_at)
#  index_tickets_on_source                                (source)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#
class Ticket < ApplicationRecord
  SOURCES = %w[admin widget api].freeze

  ## SCOPES
  scope :ordered, -> { order(created_at: :desc) }
  scope :on_roadmap, -> { where(public_on_roadmap: true) }
  scope :scheduled, -> { where.not(scheduled_for: nil).where(shipped_at: nil) }
  scope :shipped, -> { where.not(shipped_at: nil) }
  scope :bugs, -> { where(classification: :bug) }
  scope :features, -> { where(classification: :feature_request) }
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  enum :status, {new: 0, in_progress: 10, completed: 100}, suffix: true, validate: true, default: :new
  enum :classification, {unclassified: 0, bug: 1, feature_request: 10, task: 100}, validate: true,
    default: :unclassified

  ## ASSOCIATIONS
  belongs_to :contact, optional: true
  has_many :ticket_votes, dependent: :destroy
  has_many :voters, through: :ticket_votes, source: :contact
  ## VALIDATIONS
  validates :title, presence: true
  validates :source, inclusion: {in: SOURCES}

  ## CALLBACKS
  ## OTHER

  def to_s
    title
  end

  private

  ## callback methods
end
