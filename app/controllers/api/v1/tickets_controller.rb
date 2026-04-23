module Api
  module V1
    class TicketsController < BaseController
      VOTABLE_CLASSIFICATIONS = %w[feature_request].freeze

      before_action :find_visible_ticket, only: %i[show vote unvote]

      def index
        if ActiveModel::Type::Boolean.new.cast(params[:mine])
          scope = Ticket.where(contact_id: Current.contact.id).order(created_at: :desc)
          scope = with_voted_by_me(scope)
          render json: TicketBlueprint.render(scope, contact: Current.contact)
          return
        end

        sort = (params[:sort] == "new") ? "new" : "top"
        type = params[:type].presence || "feature"

        scope = Ticket.on_roadmap.where(classification: classification_for(type))
        scope = with_voted_by_me(scope)
        scope = (sort == "new") ? scope.order(created_at: :desc) : scope.order(votes_count: :desc, created_at: :desc)

        render json: TicketBlueprint.render(scope, contact: Current.contact)
      end

      def show
        render json: TicketBlueprint.render(@ticket, contact: Current.contact)
      end

      def create
        ticket = Ticket.new(ticket_params)
        ticket.contact = Current.contact
        ticket.source = "widget"
        ticket.public_on_roadmap = ticket.feature_request? && !ticket.bug?
        ticket.save!

        render json: TicketBlueprint.render(ticket, contact: Current.contact), status: :created
      end

      def vote
        return render_not_votable unless votable?(@ticket)

        TicketVote.find_or_create_by!(ticket: @ticket, contact: Current.contact)
        render json: vote_payload(@ticket.reload, voted: true)
      end

      def unvote
        TicketVote.where(ticket: @ticket, contact: Current.contact).destroy_all
        render json: vote_payload(@ticket.reload, voted: false)
      end

      private

      def find_visible_ticket
        ticket = Ticket.find(params[:id])
        unless ticket.public_on_roadmap || ticket.contact_id == Current.contact.id
          raise ActiveRecord::RecordNotFound
        end
        @ticket = ticket
      end

      def ticket_params
        permitted = params.require(:ticket).permit(:title, :description, :classification, context: {})
        permitted[:classification] = "feature_request" unless Ticket.classifications.key?(permitted[:classification])
        permitted
      end

      def classification_for(type)
        case type.to_s
        when "bug" then "bug"
        when "task" then "task"
        else "feature_request"
        end
      end

      def with_voted_by_me(scope)
        return scope unless Current.contact
        scope
          .left_joins(:ticket_votes)
          .select("tickets.*, BOOL_OR(ticket_votes.contact_id = #{Current.contact.id.to_i}) AS voted_by_me")
          .group("tickets.id")
      end

      def votable?(ticket)
        ticket.public_on_roadmap && VOTABLE_CLASSIFICATIONS.include?(ticket.classification)
      end

      def vote_payload(ticket, voted:)
        {id: ticket.id, votes_count: ticket.votes_count, voted_by_me: voted}
      end

      def render_not_votable
        render json: {error: "Ticket is not votable"}, status: :unprocessable_entity
      end
    end
  end
end
