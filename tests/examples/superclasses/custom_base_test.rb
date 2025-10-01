require 'minitest/autorun'

module Api
  class BaseCase < Minitest::Test; end
end

class ApiTest < Api::BaseCase
  def test_ping
    assert true
  end
end
