# frozen_string_literal: true

# Builds the four mutually exclusive lanes used by both the public API
# (Api::V1::RoadmapController, the embedded widget's Roadmap tab, and the
# /roadmap public page) and the admin timeline editor (TicketsController#timeline).
#
# A ticket appears in exactly one bucket. Priority: shipped → scheduled → now → ideas.
# A `scheduled_for` date is the strongest signal short of being shipped, so it
# trumps `in_progress` status — a ticket that's being actively worked on AND
# has a scheduled date belongs in `next`, not `now`.
#
# - shipped: shipped_at present
# - next:    scheduled_for present, not shipped (regardless of status)
# - now:     in_progress, no scheduled_for, not shipped
# - ideas:   feature requests with status: new, no scheduled_for, not shipped
class RoadmapPresenter
  DEFAULT_IDEAS_LIMIT = 10
  DEFAULT_SHIPPED_LIMIT = 25
  IDEAS_LIMIT = DEFAULT_IDEAS_LIMIT      # back-compat
  SHIPPED_LIMIT = DEFAULT_SHIPPED_LIMIT  # back-compat

  def initialize(scope: Ticket.on_roadmap,
    ideas_limit: DEFAULT_IDEAS_LIMIT,
    shipped_limit: DEFAULT_SHIPPED_LIMIT,
    ideas_classifications: [:feature_request])
    @scope = scope
    @ideas_limit = ideas_limit
    @shipped_limit = shipped_limit
    @ideas_classifications = Array(ideas_classifications)
  end

  def self.call(**opts)
    new(**opts).call
  end

  def call
    {
      now: now_tickets,
      next: next_tickets,
      shipped: shipped_tickets,
      ideas: idea_tickets
    }
  end

  private

  def now_tickets
    @scope.in_progress_status
      .where(scheduled_for: nil, shipped_at: nil)
      .order(updated_at: :desc)
      .to_a
  end

  def next_tickets
    @scope.where.not(scheduled_for: nil)
      .where(shipped_at: nil)
      .order(scheduled_for: :asc)
      .to_a
  end

  def shipped_tickets
    @scope.shipped.order(shipped_at: :desc).limit(@shipped_limit).to_a
  end

  def idea_tickets
    @scope.where(classification: @ideas_classifications)
      .new_status
      .where(scheduled_for: nil, shipped_at: nil)
      .order(votes_count: :desc, created_at: :desc)
      .limit(@ideas_limit)
      .to_a
  end
end
