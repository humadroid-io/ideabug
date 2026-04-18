# frozen_string_literal: true

class RoadmapPresenter
  IDEAS_LIMIT = 10
  SHIPPED_LIMIT = 25

  def call
    {
      now: now_tickets,
      next: next_tickets,
      shipped: shipped_tickets,
      ideas: idea_tickets
    }
  end

  def self.call(...)
    new(...).call
  end

  private

  def base
    Ticket.on_roadmap
  end

  def now_tickets
    base.in_progress_status.order(updated_at: :desc).to_a
  end

  def next_tickets
    base.scheduled.order(scheduled_for: :asc).to_a
  end

  def shipped_tickets
    base.shipped.order(shipped_at: :desc).limit(SHIPPED_LIMIT).to_a
  end

  def idea_tickets
    base.features
      .new_status
      .where(scheduled_for: nil, shipped_at: nil)
      .order(votes_count: :desc, created_at: :desc)
      .limit(IDEAS_LIMIT)
      .to_a
  end
end
