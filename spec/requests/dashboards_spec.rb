require "rails_helper"

RSpec.describe "Household dashboard", type: :request do
  let!(:user) { User.create!(name: "Bhaumik", email: "dashboard@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Water House", creator: user) }

  before { household.household_memberships.create!(user: user) }

  def login
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "requires login" do
    get household_dashboard_path(household)

    expect(response).to redirect_to(login_path)
  end

  it "shows the selected household and its members" do
    login
    get household_dashboard_path(household)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Water House", "Bhaumik", "1 member", "Household dashboard")
  end

  it "distinguishes unavailable summaries from zero outstanding responsibilities" do
    login
    get household_dashboard_path(household)

    page = Nokogiri::HTML(response.body)
    expect(page.css(".dashboard-card h2").map(&:text)).to eq(
      [ "Chores", "Bills & balances", "Inventory alerts", "House rules & voting" ]
    )
    expect(page.css(".dashboard-card .dashboard-status").map(&:text)).to eq([ "Not available yet" ] * 4)
    expect(response.body).not_to include("$0.00", "No upcoming tasks")
  end

  it "links to real household management and navigation pages" do
    login
    get household_dashboard_path(household)

    links = Nokogiri::HTML(response.body).css("a").map { |link| link["href"] }
    expect(links).to include(household_path(household), root_path, households_path)
    expect(links).not_to include("#", "/chores", "/bills", "/inventory", "/votes")
  end

  it "does not expose a non-member household or its invitation code" do
    private_household = Household.create!(name: "Private House", creator: user)
    login
    get household_dashboard_path(private_household)

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Private House", private_household.invite_code)
  end

  it "returns not found for an unknown household" do
    login
    get household_dashboard_path(household.id + 10_000)

    expect(response).to have_http_status(:not_found)
  end

  it "revokes dashboard access immediately after membership removal" do
    login
    household.household_memberships.destroy_all
    get household_dashboard_path(household)

    expect(response).to have_http_status(:not_found)
  end

  it "keeps member data scoped when a user has multiple households" do
    second_household = Household.create!(name: "Second House", creator: user)
    second_household.household_memberships.create!(user: user)
    roommate = User.create!(name: "Second House Roommate", email: "second@example.com", password: "password123")
    second_household.household_memberships.create!(user: roommate)
    login
    get household_dashboard_path(household)

    expect(response.body).not_to include("Second House Roommate", second_household.invite_code)
    get household_dashboard_path(second_household)
    expect(response.body).to include("Second House Roommate", "2 members")
  end

  it "escapes household and member names" do
    household.update!(name: "<script>alert('house')</script>")
    user.update!(name: "<script>alert('member')</script>")
    login
    get household_dashboard_path(household)

    expect(response.body).to include("&lt;script&gt;")
    expect(response.body).not_to include(household.name, user.name)
  end

  it "links from household details to the dashboard" do
    login
    get household_path(household)

    expect(response.body).to include("href=\"#{household_dashboard_path(household)}\"")
  end

  it "offers only the current user's households on the home page" do
    Household.create!(name: "Unjoined House", creator: user)
    login
    get root_path

    expect(response.body).to include("Water House", household_dashboard_path(household))
    expect(response.body).not_to include("Unjoined House")
  end

  it "guides a user without a household to create or join one" do
    household.household_memberships.destroy_all
    login
    get root_path

    expect(response.body).to include("Create or join your first household")
    expect(response.body).to include("href=\"#{new_household_path}\"", "href=\"#{join_household_path}\"")
  end
end
