require "rails_helper"

RSpec.describe Household, type: :model do
  let(:creator) do
  User.create!(
    name: "Aditi",
    email: "aditi@example.com",
    password: "password123"
  )
end

  it "is valid with a name and creator" do
    household = Household.new(
      name: "Apartment 101",
      creator: creator
    )

    expect(household).to be_valid
  end

  it "requires a household name" do
    household = Household.new(
      creator: creator
    )

    expect(household).not_to be_valid
  end

  it "requires a creator" do
    household = Household.new(
      name: "Apartment 101"
    )

    expect(household).not_to be_valid
  end

  describe "map_link validation" do
    it "allows blank map_link" do
      household = Household.new(name: "Apt 101", creator: creator, map_link: "")
      expect(household).to be_valid
    end

    it "allows nil map_link" do
      household = Household.new(name: "Apt 101", creator: creator, map_link: nil)
      expect(household).to be_valid
    end

    it "allows valid http and https URLs" do
      ["https://maps.google.com/?q=Texas+Ave", "http://maps.apple.com/?q=Campus"].each do |url|
        household = Household.new(name: "Apt 101", creator: creator, map_link: url)
        expect(household).to be_valid
      end
    end

    it "rejects dangerous or invalid schemes" do
      ["javascript:alert(1)", "data:text/html;base64,PHNjcmlwdD4=", "ftp://maps.example.com", "random string"].each do |url|
        household = Household.new(name: "Apt 101", creator: creator, map_link: url)
        expect(household).not_to be_valid
        expect(household.errors[:map_link]).to include("must start with http:// or https://")
      end
    end
  end
end
