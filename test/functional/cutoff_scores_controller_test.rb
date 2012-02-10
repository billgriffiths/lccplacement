require File.dirname(__FILE__) + '/../test_helper'
require 'cutoff_scores_controller'

# Re-raise errors caught by the controller.
class CutoffScoresController; def rescue_action(e) raise e end; end

class CutoffScoresControllerTest < Test::Unit::TestCase
  fixtures :cutoff_scores

  def setup
    @controller = CutoffScoresController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = cutoff_scores(:first).id
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

    assert_not_nil assigns(:cutoff_scores)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:cutoff_score)
    assert assigns(:cutoff_score).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:cutoff_score)
  end

  def test_create
    num_cutoff_scores = CutoffScore.count

    post :create, :cutoff_score => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_cutoff_scores + 1, CutoffScore.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:cutoff_score)
    assert assigns(:cutoff_score).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      CutoffScore.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      CutoffScore.find(@first_id)
    }
  end
end
