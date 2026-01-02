require "test_helper"

class Api::V1::Admin::MenuImagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_admin_menu_images_index_url
    assert_response :success
  end

  test "should get create" do
    get api_v1_admin_menu_images_create_url
    assert_response :success
  end

  test "should get destroy" do
    get api_v1_admin_menu_images_destroy_url
    assert_response :success
  end
end
