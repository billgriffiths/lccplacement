require File.dirname(__FILE__) + '/../test_helper'
require 'test_session_controller'

# Re-raise errors caught by the controller.
class TestSessionController; def rescue_action(e) raise e end; end

class TestSessionControllerTest < Test::Unit::TestCase
  def setup
    @controller = TestSessionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
