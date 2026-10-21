Feature: Expense Tracking
  As a roommate
  I want to track and split shared expenses
  So that finances remain transparent

  Background:
    Given I am a member of "Apartment 101"
    And there are 3 roommates total

  Scenario: Recording expense with equal split
    When I click "Add Expense"
    And I enter amount "150.00"
    And I enter description "Groceries"
    And I select "Split Equally"
    And I click "Save Expense"
    Then each roommate owes "50.00"
    And the expense appears in history

  Scenario: Recording expense with custom split
    When I click "Add Expense"
    And I enter amount "100.00"
    And I set custom splits "60%, 30%, 10%"
    And I click "Save Expense"
    Then balances show "60.00", "30.00", "10.00"
    And totals equal "100.00"

  Scenario: Invalid expense amount
    When I click "Add Expense"
    And I enter amount "-50"
    And I click "Save Expense"
    Then I should see "Amount must be positive"

  Scenario: Marking payment as complete
    Given I owe "50.00" for groceries
    When I mark expense as "Paid"
    Then my balance shows "0.00"
    And payment history shows my payment
