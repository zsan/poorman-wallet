require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get login_url
    assert_response :success
  end

  test "should get create" do
    user = users(:one)
    sign_in_as(user)
    assert_response :redirect
  end

  test "should get destroy" do
    delete logout_url
    assert_response :redirect
  end
end
