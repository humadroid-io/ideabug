# == Schema Information
#
# Table name: tickets
#
#  id             :bigint           not null, primary key
#  classification :integer          default("unclassified")
#  description    :text
#  status         :integer          default("new")
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
FactoryBot.define do
  factory :ticket do
    sequence(:title) { |n| "Ticket #{n}" }
    description { "Sample description" }
    status { :new }
    classification { :unclassified }
  end
end
