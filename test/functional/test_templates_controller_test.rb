require File.dirname(__FILE__) + '/../test_helper'
require 'test_templates_controller'

# Re-raise errors caught by the controller.
class TestTemplatesController; def rescue_action(e) raise e end; end

class TestTemplatesControllerTest < Test::Unit::TestCase
  fixtures :test_templates

  def setup
    @controller = TestTemplatesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = test_templates(:first).id
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

    assert_not_nil assigns(:test_templates)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:test_template)
    assert assigns(:test_template).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:test_template)
  end

  def test_create
    num_test_templates = TestTemplate.count

    post :create, :test_template => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_test_templates + 1, TestTemplate.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:test_template)
    assert assigns(:test_template).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      TestTemplate.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      TestTemplate.find(@first_id)
    }
  end
end
