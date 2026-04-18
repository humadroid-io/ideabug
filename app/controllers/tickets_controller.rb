class TicketsController < ApplicationController
  before_action :set_ticket, only: %i[show edit update destroy]

  def index
    scope = filtered_scope
    respond_to do |format|
      format.html { @pagy, @tickets = pagy(scope) }
      format.json { @tickets = scope.to_a }
    end
  end

  def timeline
    @now = Ticket.on_roadmap.in_progress_status.order(updated_at: :desc)
    @next = Ticket.on_roadmap.scheduled.order(scheduled_for: :asc)
    @shipped = Ticket.on_roadmap.shipped.order(shipped_at: :desc).limit(25)
    @backlog = Ticket.on_roadmap.features.new_status
      .where(scheduled_for: nil, shipped_at: nil)
      .order(votes_count: :desc, created_at: :desc)
      .limit(25)
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
