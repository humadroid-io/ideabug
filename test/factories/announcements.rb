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
FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "Announcement #{n}" }
    preview { "Sample preview text" }
    content { "Sample content" }
  end
end
