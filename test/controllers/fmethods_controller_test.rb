require 'test_helper'

class FmethodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fmethod = fmethods(:one)
  end

  test "should get index" do
    get fmethods_url
    assert_response :success
  end

  test "should get new" do
    get new_fmethod_url
    assert_response :success
  end

  test "should create fmethod" do
    assert_difference('Fmethod.count') do
      post fmethods_url, params: { fmethod: { file_name: @fmethod.file_name, name: @fmethod.name, remark1: @fmethod.remark1, remark2: @fmethod.remark2 } }
    end

    assert_redirected_to fmethod_url(Fmethod.last)
  end

  test "should show fmethod" do
    get fmethod_url(@fmethod)
    assert_response :success
  end

  test "should get edit" do
    get edit_fmethod_url(@fmethod)
    assert_response :success
  end

  test "should update fmethod" do
    patch fmethod_url(@fmethod), params: { fmethod: { file_name: @fmethod.file_name, name: @fmethod.name, remark1: @fmethod.remark1, remark2: @fmethod.remark2 } }
    assert_redirected_to fmethod_url(@fmethod)
  end

  test "should destroy fmethod" do
    assert_difference('Fmethod.count', -1) do
      delete fmethod_url(@fmethod)
    end

    assert_redirected_to fmethods_url
  end
end
