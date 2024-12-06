# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  info_payload :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#
# Indexes
#
#  index_contacts_on_external_id  (external_id) UNIQUE
#
FactoryBot.define do
  factory :contact do
    sequence(:external_id) { |n| n }
    info_payload { {} }
  end
end
