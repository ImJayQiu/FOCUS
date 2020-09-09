require "application_system_test_case"

class WikiPagesTest < ApplicationSystemTestCase
  setup do
    @wiki_page = wiki_pages(:one)
  end

  test "visiting the index" do
    visit wiki_pages_url
    assert_selector "h1", text: "Wiki Pages"
  end

  test "creating a Wiki page" do
    visit wiki_pages_url
    click_on "New Wiki Page"

    fill_in "Chapter", with: @wiki_page.chapter
    fill_in "Content", with: @wiki_page.content
    fill_in "Heading1", with: @wiki_page.heading1
    fill_in "Heading2", with: @wiki_page.heading2
    fill_in "Heading3", with: @wiki_page.heading3
    fill_in "Image1", with: @wiki_page.image1
    fill_in "Image2", with: @wiki_page.image2
    fill_in "Title", with: @wiki_page.title
    click_on "Create Wiki page"

    assert_text "Wiki page was successfully created"
    click_on "Back"
  end

  test "updating a Wiki page" do
    visit wiki_pages_url
    click_on "Edit", match: :first

    fill_in "Chapter", with: @wiki_page.chapter
    fill_in "Content", with: @wiki_page.content
    fill_in "Heading1", with: @wiki_page.heading1
    fill_in "Heading2", with: @wiki_page.heading2
    fill_in "Heading3", with: @wiki_page.heading3
    fill_in "Image1", with: @wiki_page.image1
    fill_in "Image2", with: @wiki_page.image2
    fill_in "Title", with: @wiki_page.title
    click_on "Update Wiki page"

    assert_text "Wiki page was successfully updated"
    click_on "Back"
  end

  test "destroying a Wiki page" do
    visit wiki_pages_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Wiki page was successfully destroyed"
  end
end
