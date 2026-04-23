class PublicRoadmapController < ApplicationController
  allow_unauthenticated_access only: :index
  layout "public"

  def index
    @buckets = RoadmapPresenter.call
  end
end
