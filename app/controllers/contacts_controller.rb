class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show destroy]

  # GET /contacts or /contacts.json
  def index
    @contacts = Contact.all
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
