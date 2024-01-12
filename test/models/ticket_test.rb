# == Schema Information
#
# Table name: tickets
#
#  id             :bigint           not null, primary key
#  classification :integer          default("unclassified")
#  description    :text
#  status         :integer          default("new")
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class TicketTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
