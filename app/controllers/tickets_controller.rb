class TicketsController < ApplicationController
  TRANSITIONS = %w[start ship unschedule reopen].freeze

  before_action :set_ticket, only: %i[show edit update destroy transition]

  def index
    scope = filtered_scope
    respond_to do |format|
      format.html { @pagy, @tickets = pagy(scope) }
      format.json { @tickets = scope.to_a }
    end
  end

  def timeline
    buckets = RoadmapPresenter.call(ideas_limit: 25, shipped_limit: 25)
    @now = buckets[:now]
    @next = buckets[:next]
    @shipped = buckets[:shipped]
    @backlog = buckets[:ideas]
  end

  def show
  end

  def new
    @ticket = Ticket.new
  end

  def edit
  end

  def create
    @ticket = Ticket.new(ticket_params)

    respond_to do |format|
      if @ticket.save
        format.html { redirect_to ticket_url(@ticket), notice: "Ticket was successfully created." }
        format.json { render :show, status: :created, location: @ticket }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @ticket.update(ticket_params)
        format.html { redirect_to ticket_url(@ticket), notice: "Ticket was successfully updated." }
        format.json { render :show, status: :ok, location: @ticket }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @ticket.destroy!

    respond_to do |format|
      format.html { redirect_to tickets_url, notice: "Ticket was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def transition
    to = params[:to].to_s
    return redirect_back(fallback_location: timeline_tickets_path, alert: "Unknown transition") unless TRANSITIONS.include?(to)

    case to
    when "start"
      @ticket.update!(status: :in_progress, shipped_at: nil)
    when "ship"
      @ticket.update!(status: :completed, shipped_at: Time.current)
    when "unschedule"
      @ticket.update!(scheduled_for: nil)
    when "reopen"
      @ticket.update!(status: :in_progress, shipped_at: nil)
    end

    redirect_back(fallback_location: timeline_tickets_path, notice: "Ticket updated.")
  end

  private

  def filtered_scope
    scope = Ticket.includes(:contact)
    if (cls = params[:classification].presence) && Ticket.classifications.key?(cls)
      scope = scope.where(classification: cls)
    end
    if (st = params[:status].presence) && Ticket.statuses.key?(st)
      scope = scope.where(status: st)
    end
    if (q = params[:q].to_s.strip).present?
      like = "%#{q}%"
      scope = scope.where("title ILIKE ? OR description ILIKE ?", like, like)
    end
    case params[:sort]
    when "votes" then scope.order(votes_count: :desc, created_at: :desc)
    else scope.order(created_at: :desc)
    end
  end

  def set_ticket
    @ticket = Ticket.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:title, :description, :status, :classification,
      :public_on_roadmap, :scheduled_for, :shipped_at)
  end
end
