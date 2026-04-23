class PublicFeaturesController < ApplicationController
  allow_unauthenticated_access only: :show
  layout "public"

  before_action :set_feature

  def show
  end

  private

  def set_feature
    @feature = Ticket.features.on_roadmap.find(params[:id])
  end
end
