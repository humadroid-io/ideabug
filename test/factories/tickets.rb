# == Schema Information
#
# Table name: tickets
#
#  id                :bigint           not null, primary key
#  classification    :integer          default("unclassified")
#  context           :jsonb
#  description       :text
#  public_on_roadmap :boolean          default(FALSE), not null
#  scheduled_for     :datetime
#  shipped_at        :datetime
#  source            :string           default("admin"), not null
#  status            :integer          default("new")
#  title             :string
#  votes_count       :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  contact_id        :bigint
#
# Indexes
#
#  index_tickets_on_classification_and_status             (classification,status)
#  index_tickets_on_contact_id                            (contact_id)
#  index_tickets_on_public_on_roadmap_and_classification  (public_on_roadmap,classification)
#  index_tickets_on_scheduled_for                         (scheduled_for)
#  index_tickets_on_shipped_at                            (shipped_at)
#  index_tickets_on_source                                (source)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#
FactoryBot.define do
  factory :ticket do
    sequence(:title) { |n| "Ticket #{n}" }
    description { "Sample description" }
    status { :new }
    classification { :unclassified }
    source { "admin" }

    trait :feature do
      classification { :feature_request }
      public_on_roadmap { true }
    end

    trait :bug do
      classification { :bug }
    end

    trait :scheduled do
      scheduled_for { 2.weeks.from_now }
    end

    trait :shipped do
      shipped_at { 1.week.ago }
      status { :completed }
    end
  end
end
