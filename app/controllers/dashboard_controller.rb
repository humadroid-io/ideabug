class DashboardController < ApplicationController
  STATS_CACHE_TTL = 5.minutes

  def index
    @stats = Rails.cache.fetch("dashboard:stats", expires_in: STATS_CACHE_TTL) { build_stats }
    @top_features = Ticket.features.on_roadmap.where(shipped_at: nil)
      .order(votes_count: :desc, created_at: :desc).limit(5)
    @recent_bugs = Ticket.bugs.order(created_at: :desc).limit(5)
    @reads_by_week = AnnouncementRead
      .where("created_at > ?", 8.weeks.ago)
      .group("date_trunc('week', created_at)")
      .count
      .sort_by { |k, _| k }
  end

  private

  def build_stats
    {
      contacts_total: Contact.count,
      contacts_identified: Contact.identified.count,
      contacts_anonymous: Contact.anonymous.count,
      contacts_active_24h: Contact.where("last_seen_at > ?", 24.hours.ago).count,
      tickets_by_status: Ticket.group(:classification, :status).count,
      announcements_total: Announcement.count,
      announcements_last_30d: Announcement.where("published_at > ?", 30.days.ago).count,
      reads_last_7d: AnnouncementRead.where("created_at > ?", 7.days.ago).count,
      votes_last_7d: TicketVote.where("created_at > ?", 7.days.ago).count
    }
  end
end
