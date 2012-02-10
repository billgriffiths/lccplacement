require File.dirname(__FILE__) + '/../test_helper'
require 'test_sequence_controller'

# Re-raise errors caught by the controller.
class TestSequenceController; def rescue_action(e) raise e end; end

class TestSequenceControllerTest < Test::Unit::TestCase
  fixtures :test_sequences

  def setup
    @controller = TestSequenceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = test_sequences(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:test_sequences)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:test_sequence)
    assert assigns(:test_sequence).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:test_sequence)
  end

  def test_create
    num_test_sequences = TestSequence.count

    post :create, :test_sequence => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_test_sequences + 1, TestSequence.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:test_sequence)
    assert assigns(:test_sequence).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      TestSequence.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      TestSequence.find(@first_id)
    }
  end
end
