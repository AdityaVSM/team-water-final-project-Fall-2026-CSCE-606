
require "rails_helper"

RSpec.describe HouseholdMembership, type: :model do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
  end

  let(:household) do
    Household.create!(
      name: "Apartment 101",
      creator: user
    )
  end

  it "allows a valid household membership" do
    membership = HouseholdMembership.new(
      user: user,
      household: household
    )

    expect(membership).to be_valid
  end

  it "requires a user" do
    membership = HouseholdMembership.new(
      household: household
    )

    expect(membership).not_to be_valid
    expect(membership.errors[:user]).not_to be_empty
  end

  it "requires a household" do
    membership = HouseholdMembership.new(
      user: user
    )

    expect(membership).not_to be_valid
    expect(membership.errors[:household]).not_to be_empty
  end

  it "prevents duplicate household memberships" do
    HouseholdMembership.create!(
      user: user,
      household: household
    )

    duplicate = HouseholdMembership.new(
      user: user,
      household: household
    )

    expect(duplicate).not_to be_valid
  end
end
