class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show destroy]

  # GET /contacts or /contacts.json
  def index
    scope = Contact.order(last_seen_at: :desc, created_at: :desc)

    case params[:type]
    when "identified" then scope = scope.identified
    when "anonymous"  then scope = scope.anonymous
    end

    if params[:active] == "24h"
      scope = scope.where("last_seen_at > ?", 24.hours.ago)
    end

    if (q = params[:q].to_s.strip).present?
      like = "%#{q}%"
      scope = scope.where("external_id ILIKE ? OR anonymous_id ILIKE ?", like, like)
    end

    respond_to do |format|
      format.html { @pagy, @contacts = pagy(scope) }
      format.json { @contacts = scope.to_a }
    end
  end

  # GET /contacts/1 or /contacts/1.json
  def show
  end

  # DELETE /contacts/1 or /contacts/1.json
  def destroy
    @contact.destroy!

    respond_to do |format|
      format.html { redirect_to contacts_path, status: :see_other, notice: "Contact was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def contact_params
    params.expect(contact: [:external_id, :info_payload])
  end
end
