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
FactoryBot.define do
  factory :contact do
    sequence(:external_id) { |n| "ext-#{n}" }
    info_payload { {} }

    trait :anonymous do
      external_id { nil }
      sequence(:anonymous_id) { |n| "ib_anon_#{n}" }
    end

    trait :identified do
      anonymous_id { nil }
    end
  end
end
