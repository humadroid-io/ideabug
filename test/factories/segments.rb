# == Schema Information
#
# Table name: segments
#
#  id               :bigint           not null, primary key
#  allow_new_values :boolean          default(FALSE)
#  identifier       :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_segments_on_identifier  (identifier) UNIQUE
#
FactoryBot.define do
  factory :segment do
    sequence(:identifier) { |n| "Segment #{n}" }
    allow_new_values { true }
  end
end
