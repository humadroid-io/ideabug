# == Schema Information
#
# Table name: announcements
#
#  id         :bigint           not null, primary key
#  preview    :text
#  title      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
  end

  context "#to_s" do
    should "return the title" do
      announcement = build(:announcement, title: "Test Announcement")
      assert_equal "Test Announcement", announcement.to_s
    end
  end
end
