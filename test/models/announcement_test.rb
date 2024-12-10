# == Schema Information
#
# Table name: announcements
#
#  id           :bigint           not null, primary key
#  preview      :text
#  published_at :datetime         not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_announcements_on_published_at  (published_at)
#
require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of(:title)
  end

  context "factory" do
    should "be valid" do
      assert build(:announcement).valid?
    end
  end

  context "associations" do
    should have_rich_text(:content)
    should have_many(:announcement_reads)
  end

  context "#to_s" do
    should "return the title" do
      announcement = build(:announcement, title: "Test Announcement")
      assert_equal "Test Announcement", announcement.to_s
    end
  end

  context "#read" do
    setup do
      @contact = create(:contact)
      @announcement = create(:announcement)
      Current.contact = @contact
    end

    should "return read attribute if present" do
      announcement = Announcement
        .select("announcements.*, true as read")
        .find(@announcement.id)
      assert announcement.read
    end

    should "return cached value if set" do
      @announcement.instance_variable_set(:@read, true)
      assert @announcement.read
    end

    should "return false if no announcement_reads exist" do
      refute @announcement.read
    end

    should "return true if announcement_read exists for contact" do
      create(:announcement_read, announcement: @announcement, contact: @contact)
      assert @announcement.read
    end

    teardown do
      Current.contact = nil
    end
  end
end
