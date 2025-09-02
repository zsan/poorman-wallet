require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    user = users(:one)
    sign_in_as(user)
    get dashboard_url
    assert_response :success
  end
end
