# == Schema Information
#
# Table name: contacts
#
#  id                      :bigint           not null, primary key
#  announcements_opted_out :boolean          default(FALSE), not null
#  info_payload            :jsonb
#  last_seen_at            :datetime
#  segments_payload        :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  anonymous_id            :string
#  external_id             :string
#
# Indexes
#
#  index_contacts_on_anonymous_id  (anonymous_id) UNIQUE WHERE (anonymous_id IS NOT NULL)
#  index_contacts_on_external_id   (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#
require "test_helper"

class ContactTest < ActiveSupport::TestCase
  context "factory" do
    should "be valid" do
      assert build(:contact).valid?
    end

    should "build a valid anonymous contact" do
      contact = build(:contact, :anonymous)
      assert contact.valid?, contact.errors.full_messages.to_sentence
      assert contact.anonymous?
      refute contact.identified?
    end
  end

  context "identity invariant" do
    should "be invalid without external_id or anonymous_id" do
      contact = build(:contact, external_id: nil, anonymous_id: nil)
      refute contact.valid?
      assert_includes contact.errors[:base], "must have either external_id or anonymous_id"
    end

    should "validate external_id uniqueness only when present" do
      create(:contact, external_id: "dup")
      assert_not build(:contact, external_id: "dup").valid?
      # two anonymous contacts with nil external_id are fine
      create(:contact, :anonymous)
      assert build(:contact, :anonymous).valid?
    end

    should "validate anonymous_id uniqueness only when present" do
      create(:contact, :anonymous, anonymous_id: "ib_dup")
      assert_not build(:contact, :anonymous, anonymous_id: "ib_dup").valid?
    end
  end

  context "scopes" do
    should "split anonymous and identified" do
      anon = create(:contact, :anonymous)
      ident = create(:contact, :identified)

      assert_includes Contact.anonymous, anon
      refute_includes Contact.anonymous, ident

      assert_includes Contact.identified, ident
      refute_includes Contact.identified, anon
    end
  end

  test "updates segments from payload" do
    segment = create(:segment, identifier: "region", allow_new_values: true)
    existing_value = create(:segment_value, segment: segment, val: "north")

    contact = create(:contact)

    segments_data = {
      "region" => "north",
      "country" => "us"
    }

    contact.update_segments_from_payload(segments_data)

    assert_equal segments_data, contact.segments_payload
    assert_includes contact.segment_values, existing_value
  end

  test "creates new segment value when allowed" do
    segment = create(:segment, identifier: "region", allow_new_values: true)

    contact = create(:contact)

    segments_data = {"region" => "south"}

    assert_difference "SegmentValue.count", 1 do
      contact.update_segments_from_payload(segments_data)
    end

    new_value = segment.segment_values.find_by(val: "south")
    assert_includes contact.segment_values, new_value
  end

  test "does not create new segment value when not allowed" do
    create(:segment, identifier: "region", allow_new_values: false)

    contact = create(:contact)

    segments_data = {"region" => "south"}

    assert_no_difference "SegmentValue.count" do
      contact.update_segments_from_payload(segments_data)
    end
  end

  test "does not bump updated_at when payload hasn't changed" do
    segment = create(:segment, identifier: "region", allow_new_values: true)
    create(:segment_value, segment: segment, val: "north")
    contact = create(:contact, segments_payload: {"region" => "north"})
    contact.update_columns(updated_at: 1.day.ago)
    before = contact.reload.updated_at

    contact.update_segments_from_payload({"region" => "north"})

    assert_equal before, contact.reload.updated_at
  end

  test "handles mixed string and symbol keys when comparing payloads" do
    segment = create(:segment, identifier: "region", allow_new_values: true)
    create(:segment_value, segment: segment, val: "north")
    contact = create(:contact, segments_payload: {"region" => "north"})
    contact.update_columns(updated_at: 1.day.ago)
    before = contact.reload.updated_at

    contact.update_segments_from_payload({region: "north"})
    contact.update_segments_from_payload({"REGION" => "north"})
    assert_equal before, contact.reload.updated_at

    contact.update_segments_from_payload({region: "south"})
    assert_not_equal before, contact.reload.updated_at
  end

  test "replaces stale segment memberships when a payload value changes" do
    segment = create(:segment, identifier: "region", allow_new_values: true)
    north = create(:segment_value, segment: segment, val: "north")
    south = create(:segment_value, segment: segment, val: "south")
    contact = create(:contact, segments_payload: {"region" => "north"})
    contact.segment_values << north

    contact.update_segments_from_payload({"region" => "south"})

    contact.reload
    assert_equal({"region" => "south"}, contact.segments_payload)
    assert_equal [south.id], contact.segment_values.where(segment: segment).pluck(:id)
  end
end
