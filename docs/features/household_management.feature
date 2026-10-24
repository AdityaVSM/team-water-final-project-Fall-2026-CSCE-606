Feature: Household Management
  As a registered user
  I want to create and manage households
  So that roommates can collaborate

  Background:
    Given I am logged in as "john@example.com"

  Scenario: Creating a new household
    When I click "Create Household"
    And I fill in "Household Name" with "Apartment 101"
    And I fill in "Address" with "123 Main St"
    And I click "Create"
    Then I should see "Household created successfully"
    And I should see an invite code
    And I should be the household admin

  Scenario: Joining household with valid invite code
    Given a household exists with invite code "ABC123"
    When I visit the join household page
    And I enter invite code "ABC123"
    And I click "Join Household"
    Then I should see "Successfully joined household"
    And I should have regular member permissions

  Scenario: Joining household with invalid invite code
    When I visit the join household page
    And I enter invite code "INVALID"
    And I click "Join Household"
    Then I should see "Invalid or expired invite code"
    And I should not be part of any household

  Scenario: Cannot join multiple households
    Given I am already a member of "Apartment 101"
    When I try to join another household with code "XYZ789"
    Then I should see "You can only be in one household"
