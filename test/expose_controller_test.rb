require File.dirname(__FILE__) + '/../../../../test/test_helper'


class ExposeController < ActionController::Base
  expose :get, :index

  def index
    render :text => "Base/Index"
  end
  
  expose [:put, :post], :create
  
  def create
    render :text => "Base/Create"
  end
  
  
  def destroy
    # this method is NOT exposed
  end
end

class FirstController < ExposeController
  
  # not exposed because this is an overriden method
  def index
    render :text => "First/Index"
  end
  
  # this is not exposed
  def create
  end
  
  expose :delete, :destroy
  def destroy
    render :text => "First/Destroy"
  end
end


class SecondController < ExposeController
  # this is only postable, not gettable
  expose :post, :index
  def index
    render :text => "Second/Index"
  end

  #silly as it may seem, this is only for tests
  expose :get, :destroy
  def destroy
    render :text => "Second/Destroy"
  end
end



class ExposeControllerTest < Test::Unit::TestCase
  def setup
    @base_controller = ExposeController.new
    @first_controller = FirstController.new
    @second_controller = SecondController.new
    
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_not_override_404
    @controller = @base_controller
    get :aaaaaaaaaaaa
    
    assert_response 404
  end

  def test_in_base_controller_only_use_its_expose
    @controller = @base_controller
    get :index
    
    assert_response :success
    assert_equal "Base/Index", @response.body
    
    post :index
    assert_response 405
    
    put :create
    assert_response :success
    assert_equal "Base/Create", @response.body
    
    post :create
    assert_response :success
    assert_equal "Base/Create", @response.body
    
    get :destroy
    assert_response 405
    
    delete :destroy
    assert_response 405
  end
  
  def test_expose_is_not_inherited_but_methods_are
    # when a method is overriden, then access control from base class is not used
    @controller = @first_controller
    get :index
    
    assert_response 405
    
    @controller = @second_controller
    get :index
    assert_response 405
    
    post :index
    assert_response :success
    assert_equal "Second/Index", @response.body
    
    get :create
    assert_response 405
    
    post :create
    assert_response :success
    assert_equal "Base/Create", @response.body
    
    put :create
    assert_response :success
    assert_equal "Base/Create", @response.body
  end
  
  def test_sibling_controller_do_not_mismatch_exposes
    @controller = @second_controller
    get :destroy
    assert_response :success
    assert_equal "Second/Destroy", @response.body
    
    delete :destroy
    assert_response 405
    
    @controller = @first_controller
    delete :destroy
    assert_response :success
    
    get :destroy
    assert_response 405
  end
  
end
