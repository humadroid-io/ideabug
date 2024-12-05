# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Set up FactoryBot methods
  include FactoryBot::Syntax::Methods

  # Test validations from has_secure_password
  should have_secure_password
  should validate_presence_of(:password)
  should validate_presence_of(:email_address)

  # Test associations
  should have_many(:sessions).dependent(:destroy)

  # Test email normalization
  test "normalizes email address" do
    user = create(:user, email_address: " TEST@ExaMPLE.com ")
    assert_equal "test@example.com", user.email_address
  end

  # Test email uniqueness
  test "validates email uniqueness" do
    existing_user = create(:user)
    duplicate_user = build(:user, email_address: existing_user.email_address)
    assert_not duplicate_user.valid?
  end

  # Test user creation with valid attributes
  test "creates user with valid attributes" do
    user = build(:user)
    assert user.valid?
  end
end
