require "rails_helper"

RSpec.describe HouseholdMembership, type: :model do
  let(:user) do
    User.create!(
      name: "Aditi",
      email: "aditi@example.com"
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
      household: household,
      role: "member"
    )

    expect(membership).to be_valid
  end

  it "allows an admin role" do
    membership = HouseholdMembership.new(
      user: user,
      household: household,
      role: "admin"
    )

    expect(membership).to be_valid
  end

  it "rejects an invalid role" do
    membership = HouseholdMembership.new(
      user: user,
      household: household,
      role: "superadmin"
    )

    expect(membership).not_to be_valid
  end

  it "prevents duplicate household memberships" do
    HouseholdMembership.create!(
      user: user,
      household: household,
      role: "member"
    )

    duplicate = HouseholdMembership.new(
      user: user,
      household: household,
      role: "member"
    )

    expect(duplicate).not_to be_valid
  end
end