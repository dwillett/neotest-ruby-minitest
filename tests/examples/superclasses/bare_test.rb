require "minitest/autorun"

class TestCase < Minitest::Test; end

class Bare < TestCase
  def test_custom
    assert true
  end
end

