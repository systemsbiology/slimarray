require File.dirname(__FILE__) + '/../test_helper'

class ChargeTest < Test::Unit::TestCase
  fixtures :charges

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Charge, charges(:first)
  end
end
