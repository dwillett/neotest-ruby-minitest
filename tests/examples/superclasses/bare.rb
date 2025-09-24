require "minitest/autorun"

class TestCase < Minitest::Test; end

class CustomTestCaseTest < TestCase
  def test_custom
    assert true
  end
end

