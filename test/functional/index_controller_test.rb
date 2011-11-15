require 'test_helper'

class IndexControllerTest < ActionController::TestCase
  should "get index" do
    get :index
    assert_response :success
  end

end
