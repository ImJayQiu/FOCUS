require "application_system_test_case"

class RmethodsTest < ApplicationSystemTestCase
  setup do
    @rmethod = rmethods(:one)
  end

  test "visiting the index" do
    visit rmethods_url
    assert_selector "h1", text: "Rmethods"
  end

  test "creating a Rmethod" do
    visit rmethods_url
    click_on "New Rmethod"

    fill_in "Fname", with: @rmethod.fname
    fill_in "Name", with: @rmethod.name
    fill_in "Remark", with: @rmethod.remark
    click_on "Create Rmethod"

    assert_text "Rmethod was successfully created"
    click_on "Back"
  end

  test "updating a Rmethod" do
    visit rmethods_url
    click_on "Edit", match: :first

    fill_in "Fname", with: @rmethod.fname
    fill_in "Name", with: @rmethod.name
    fill_in "Remark", with: @rmethod.remark
    click_on "Update Rmethod"

    assert_text "Rmethod was successfully updated"
    click_on "Back"
  end

  test "destroying a Rmethod" do
    visit rmethods_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Rmethod was successfully destroyed"
  end
end
