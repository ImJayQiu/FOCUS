require "application_system_test_case"

class CountriesTest < ApplicationSystemTestCase
  setup do
    @country = countries(:one)
  end

  test "visiting the index" do
    visit countries_url
    assert_selector "h1", text: "Countries"
  end

  test "creating a Country" do
    visit countries_url
    click_on "New Country"

    fill_in "Elat", with: @country.elat
    fill_in "Elon", with: @country.elon
    fill_in "Iso", with: @country.iso
    fill_in "Name", with: @country.name
    fill_in "Remark", with: @country.remark
    fill_in "Slat", with: @country.slat
    fill_in "Slon", with: @country.slon
    click_on "Create Country"

    assert_text "Country was successfully created"
    click_on "Back"
  end

  test "updating a Country" do
    visit countries_url
    click_on "Edit", match: :first

    fill_in "Elat", with: @country.elat
    fill_in "Elon", with: @country.elon
    fill_in "Iso", with: @country.iso
    fill_in "Name", with: @country.name
    fill_in "Remark", with: @country.remark
    fill_in "Slat", with: @country.slat
    fill_in "Slon", with: @country.slon
    click_on "Update Country"

    assert_text "Country was successfully updated"
    click_on "Back"
  end

  test "destroying a Country" do
    visit countries_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Country was successfully destroyed"
  end
end
