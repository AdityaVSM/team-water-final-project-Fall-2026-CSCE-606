
require "rails_helper"

RSpec.describe "Household Invitations", type: :request do
  let!(:creator) do
    User.create!(
      name: "Creator",
      email: "creator@example.com",
      password: "password123"
    )
  end

  let!(:roommate) do
    User.create!(
      name: "Roommate",
      email: "roommate@example.com",
      password: "password123"
    )
  end

  let!(:household) do
    Household.create!(
      name: "Apartment 101",
      creator: creator
    )
  end

  before do
    household.household_memberships.create!(user: creator)

    post login_path, params: {
      email: roommate.email,
      password: "password123"
    }
  end

  it "lets a roommate join with a valid code" do
    expect {
      post join_household_path,
        params: { invite_code: household.invite_code }
    }.to change(HouseholdMembership, :count).by(1)

    expect(household.users.reload).to include(roommate)
    expect(response).to redirect_to(household_path(household))
  end

  it "rejects an invalid code" do
    expect {
      post join_household_path,
        params: { invite_code: "invalid-code" }
    }.not_to change(HouseholdMembership, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "prevents duplicate membership" do
    household.household_memberships.create!(user: roommate)

    expect {
      post join_household_path,
        params: { invite_code: household.invite_code }
    }.not_to change(HouseholdMembership, :count)
  end
end
