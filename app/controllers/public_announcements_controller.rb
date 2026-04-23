class PublicAnnouncementsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  layout "public"

  before_action :enforce_public_access
  before_action :set_announcement, only: :show

  def index
    scope = published_broadcast_scope.ordered
    @pagy, @announcements = pagy(scope, limit: 20)
  end

  def show
  end

  private

  def enforce_public_access
    head :not_found unless announcements_publicly_accessible?
  end

  def published_broadcast_scope
    # Public visitors only see broadcast announcements that have already shipped.
    Announcement.where.missing(:segments).where("published_at <= ?", Time.current)
  end

  def set_announcement
    @announcement = published_broadcast_scope.find(params[:id])
  end
end
