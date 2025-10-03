require "minitest/autorun"
require "action_dispatch/system_test_case"

class BareMinimumSystemTest < ActionDispatch::SystemTestCase
  driven_by :rack_test

  test "plain visit" do
    visit "/"
  end
end

