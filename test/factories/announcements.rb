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
FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "Announcement #{n}" }
    preview { "Sample preview text" }
    published_at { Time.current }
    content { "Sample content" }
  end
end
