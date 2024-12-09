# == Schema Information
#
# Table name: segments
#
#  id               :bigint           not null, primary key
#  allow_new_values :boolean          default(FALSE)
#  identifier       :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_segments_on_identifier  (identifier) UNIQUE
#
require "test_helper"

class SegmentTest < ActiveSupport::TestCase
  context "validations" do
    subject { build(:segment, identifier: "test 1") }
    should validate_presence_of(:identifier)
    should validate_uniqueness_of(:identifier).ignoring_case_sensitivity
    should normalize(:identifier).from(" ME@XYZ.COM\n").to("me@xyz.com")
  end

  context "factory" do
    should "be valid" do
      assert build(:segment).valid?
    end
  end
end
