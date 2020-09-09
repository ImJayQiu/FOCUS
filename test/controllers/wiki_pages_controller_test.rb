require 'test_helper'

class WikiPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wiki_page = wiki_pages(:one)
  end

  test "should get index" do
    get wiki_pages_url
    assert_response :success
  end

  test "should get new" do
    get new_wiki_page_url
    assert_response :success
  end

  test "should create wiki_page" do
    assert_difference('WikiPage.count') do
      post wiki_pages_url, params: { wiki_page: { chapter: @wiki_page.chapter, content: @wiki_page.content, heading1: @wiki_page.heading1, heading2: @wiki_page.heading2, heading3: @wiki_page.heading3, image1: @wiki_page.image1, image2: @wiki_page.image2, title: @wiki_page.title } }
    end

    assert_redirected_to wiki_page_url(WikiPage.last)
  end

  test "should show wiki_page" do
    get wiki_page_url(@wiki_page)
    assert_response :success
  end

  test "should get edit" do
    get edit_wiki_page_url(@wiki_page)
    assert_response :success
  end

  test "should update wiki_page" do
    patch wiki_page_url(@wiki_page), params: { wiki_page: { chapter: @wiki_page.chapter, content: @wiki_page.content, heading1: @wiki_page.heading1, heading2: @wiki_page.heading2, heading3: @wiki_page.heading3, image1: @wiki_page.image1, image2: @wiki_page.image2, title: @wiki_page.title } }
    assert_redirected_to wiki_page_url(@wiki_page)
  end

  test "should destroy wiki_page" do
    assert_difference('WikiPage.count', -1) do
      delete wiki_page_url(@wiki_page)
    end

    assert_redirected_to wiki_pages_url
  end
end
