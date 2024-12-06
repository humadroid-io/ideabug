# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  info_payload :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#
# Indexes
#
#  index_contacts_on_external_id  (external_id) UNIQUE
#
require "test_helper"

class ContactTest < ActiveSupport::TestCase
  context "validations" do
    subject { build(:contact, external_id: "test 1") }
    should validate_presence_of(:external_id)
    should validate_uniqueness_of(:external_id)
  end

  context "factory" do
    should "be valid" do
      assert build(:contact).valid?
    end
  end
end
