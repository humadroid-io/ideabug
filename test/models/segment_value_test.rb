# == Schema Information
#
# Table name: segment_values
#
#  id         :bigint           not null, primary key
#  val        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  segment_id :bigint           not null
#
# Indexes
#
#  index_segment_values_on_segment_id  (segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (segment_id => segments.id) ON DELETE => cascade
#
require "test_helper"

class SegmentValueTest < ActiveSupport::TestCase
  context "validations" do
    subject { build(:segment_value, segment: create(:segment)) }
    should validate_presence_of(:val)
    should validate_uniqueness_of(:val).scoped_to(:segment_id)
  end

  context "factory" do
    should "be valid" do
      assert build(:segment_value).valid?
    end
  end

  context "associations" do
    should belong_to(:segment)
  end
end
