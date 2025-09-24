require "minitest/autorun"

module Api
  class BaseTestCase < Minitest::Test; end
end

class ApiTest < Api::BaseTestCase
  def test_ping
    assert true
  end
end

