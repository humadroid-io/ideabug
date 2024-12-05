ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include FactoryBot::Syntax::Methods

    def sign_in_as(user)
      post session_url, params: {email_address: user.email_address, password: user.password}
    end

    def sign_out
      delete session_url
    end
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # with.test_framework :minitest
    with.library :rails
  end
end
