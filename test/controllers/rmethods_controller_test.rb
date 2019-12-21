require 'test_helper'

class RmethodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rmethod = rmethods(:one)
  end

  test "should get index" do
    get rmethods_url
    assert_response :success
  end

  test "should get new" do
    get new_rmethod_url
    assert_response :success
  end

  test "should create rmethod" do
    assert_difference('Rmethod.count') do
      post rmethods_url, params: { rmethod: { fname: @rmethod.fname, name: @rmethod.name, remark: @rmethod.remark } }
    end

    assert_redirected_to rmethod_url(Rmethod.last)
  end

  test "should show rmethod" do
    get rmethod_url(@rmethod)
    assert_response :success
  end

  test "should get edit" do
    get edit_rmethod_url(@rmethod)
    assert_response :success
  end

  test "should update rmethod" do
    patch rmethod_url(@rmethod), params: { rmethod: { fname: @rmethod.fname, name: @rmethod.name, remark: @rmethod.remark } }
    assert_redirected_to rmethod_url(@rmethod)
  end

  test "should destroy rmethod" do
    assert_difference('Rmethod.count', -1) do
      delete rmethod_url(@rmethod)
    end

    assert_redirected_to rmethods_url
  end
end
