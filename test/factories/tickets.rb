FactoryBot.define do
  factory :ticket do
    sequence(:title) { |n| "Ticket #{n}" }
    description { "Sample description" }
    status { :new }
    classification { :unclassified }
  end
end
