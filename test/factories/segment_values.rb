# == Schema Information
#
# Table name: segment_values
#
#  id         :bigint           not null, primary key
#  val        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  segment_id :bigint           not null
#
# Indexes
#
#  index_segment_values_on_segment_id  (segment_id)
#
# Foreign Keys
#
#  fk_rails_...  (segment_id => segments.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :segment_value do
    association(:segment)
    sequence(:val) { |n| "Value #{n}"}
  end
end
