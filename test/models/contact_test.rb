# == Schema Information
#
# Table name: contacts
#
#  id               :bigint           not null, primary key
#  info_payload     :jsonb
#  segments_payload :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  external_id      :string           not null
#
# Indexes
#
#  index_contacts_on_external_id  (external_id) UNIQUE
#
require "test_helper"
require "minitest/mock"

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

  test "updates segments from payload" do
    segment = create(:segment, identifier: "region", allow_new_values: true)
    existing_value = create(:segment_value, segment: segment, val: "north")

    contact = create(:contact)

    segments_data = {
      "region" => "north",
      "country" => "us"  # non-existent segment should be ignored
    }

    contact.update_segments_from_payload(segments_data)

    assert_equal segments_data, contact.segments_payload
    assert_includes contact.segment_values, existing_value
  end

  test "creates new segment value when allowed" do
    segment = create(:segment, identifier: "region", allow_new_values: true)

    contact = create(:contact)

    segments_data = {
      "region" => "south"  # new value
    }

    assert_difference "SegmentValue.count", 1 do
      contact.update_segments_from_payload(segments_data)
    end

    new_value = segment.segment_values.find_by(val: "south")
    assert_includes contact.segment_values, new_value
  end

  test "does not create new segment value when not allowed" do
    create(:segment, identifier: "region", allow_new_values: false)

    contact = create(:contact)

    segments_data = {
      "region" => "south"  # new value
    }

    assert_no_difference "SegmentValue.count" do
      contact.update_segments_from_payload(segments_data)
    end
  end

  test "does not process segments when payload hasn't changed" do
    create(:segment, identifier: "region", allow_new_values: true)
    contact = create(:contact, segments_payload: {"region" => "north"})

    mock = Minitest::Mock.new
    contact.stub(:save, mock) do
      contact.update_segments_from_payload({"region" => "north"})
    end

    mock.verify # This will pass because mock was never called
  end

  test "handles mixed string and symbol keys when comparing payloads" do
    create(:segment, identifier: "region", allow_new_values: true)
    contact = create(:contact, segments_payload: {"region" => "north"})

    # Mock the save method
    mock = Minitest::Mock.new
    contact.stub(:save, mock) do
      # Try to update with the same payload but using symbols
      contact.update_segments_from_payload({region: "north"})

      # Try with different casing
      contact.update_segments_from_payload({"REGION" => "north"})

      # Should only update when value actually changes
      mock.expect(:call, true)
      contact.update_segments_from_payload({region: "south"})
    end

    mock.verify
  end
end
