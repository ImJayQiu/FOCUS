require "application_system_test_case"

class FmethodsTest < ApplicationSystemTestCase
  setup do
    @fmethod = fmethods(:one)
  end

  test "visiting the index" do
    visit fmethods_url
    assert_selector "h1", text: "Fmethods"
  end

  test "creating a Fmethod" do
    visit fmethods_url
    click_on "New Fmethod"

    fill_in "File name", with: @fmethod.file_name
    fill_in "Name", with: @fmethod.name
    fill_in "Remark1", with: @fmethod.remark1
    fill_in "Remark2", with: @fmethod.remark2
    click_on "Create Fmethod"

    assert_text "Fmethod was successfully created"
    click_on "Back"
  end

  test "updating a Fmethod" do
    visit fmethods_url
    click_on "Edit", match: :first

    fill_in "File name", with: @fmethod.file_name
    fill_in "Name", with: @fmethod.name
    fill_in "Remark1", with: @fmethod.remark1
    fill_in "Remark2", with: @fmethod.remark2
    click_on "Update Fmethod"

    assert_text "Fmethod was successfully updated"
    click_on "Back"
  end

  test "destroying a Fmethod" do
    visit fmethods_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Fmethod was successfully destroyed"
  end
end
