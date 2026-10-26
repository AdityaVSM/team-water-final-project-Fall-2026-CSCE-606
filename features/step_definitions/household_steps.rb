
Given("I am logged in as {string}") do |email|
  user = User.find_or_create_by!(email: email) do |u|
    u.name = email.split("@").first.capitalize
    u.password = "password123"
  end

  post "/login", email: user.email, password: "password123"

  raise "Login failed" unless last_response.redirect?

  @current_user_email = user.email
end

Given("a household named {string} exists") do |name|
  creator = User.create!(
    name: "Alice",
    email: "alice@example.com",
    password: "password123"
  )

  @household = Household.create!(
    name: name,
    creator: creator
  )

  @household.household_memberships.create!(user: creator)
end

When("I create a household named {string}") do |name|
  post "/households", household: { name: name }

  @household = Household.find_by(name: name)
  follow_redirect! if last_response.redirect?
end

When("I join {string} using its invitation code") do |name|
  household = Household.find_by!(name: name)

  post "/join-household", invite_code: household.invite_code
  follow_redirect! if last_response.redirect?

  @household = household
end

When("I try to join a household with the code {string}") do |code|
  post "/join-household", invite_code: code
end

Then("I should see the household {string}") do |name|
  unless last_response.body.include?(name)
    raise "Expected to see household '#{name}' on the page"
  end
end

Then("I should be a member of {string}") do |name|
  household = Household.find_by!(name: name)
  user = User.find_by!(email: @current_user_email)

  unless household.users.include?(user)
    raise "Expected #{user.email} to be a household member"
  end
end

Then("I should see {string}") do |message|
  unless last_response.body.include?(message)
    raise "Expected to see '#{message}' on the page"
  end
end
