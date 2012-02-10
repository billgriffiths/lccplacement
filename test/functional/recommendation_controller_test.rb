require File.dirname(__FILE__) + '/../test_helper'
require 'recommendation_controller'

# Re-raise errors caught by the controller.
class RecommendationController; def rescue_action(e) raise e end; end

class RecommendationControllerTest < Test::Unit::TestCase
  fixtures :recommendations

  def setup
    @controller = RecommendationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = recommendations(:first).id
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

    assert_not_nil assigns(:recommendations)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:recommendation)
    assert assigns(:recommendation).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:recommendation)
  end

  def test_create
    num_recommendations = Recommendation.count

    post :create, :recommendation => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_recommendations + 1, Recommendation.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:recommendation)
    assert assigns(:recommendation).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Recommendation.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Recommendation.find(@first_id)
    }
  end
end
