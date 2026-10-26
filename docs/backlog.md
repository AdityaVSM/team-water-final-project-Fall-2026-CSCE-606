
## US01 — Household Creation & Invitations

**Status:** Implemented and tested

### User Story

As a registered user,
I want to create a household or join an existing household
using an invitation code,
so that I can collaborate with my roommates in one shared space.

### Acceptance Criteria

**Scenario 1: Create a household**

Given I am a logged-in user  
When I create a household with a valid name  
Then the household should be saved  
And I should automatically become a household member  
And a unique invitation code should be generated

**Scenario 2: Join an existing household**

Given a household exists with a valid invitation code  
And I am a logged-in user  
When I submit the invitation code  
Then I should become a member of that household  
And I should be able to view its details

**Scenario 3: Invalid invitation code**

Given I am a logged-in user  
When I submit an invalid invitation code  
Then I should see an error message  
And no household membership should be created

**Scenario 4: Prevent duplicate membership**

Given I already belong to a household  
When I submit its invitation code again  
Then a duplicate membership should not be created

**Scenario 5: Protect household information**

Given I am not a member of a household  
When I attempt to access its details  
Then access should be denied

### Completed Tasks

- [x] Implement user registration and authentication
- [x] Create User, Household, and HouseholdMembership models
- [x] Implement household creation
- [x] Automatically add household creators as members
- [x] Implement unique invitation code generation
- [x] Implement join-household workflow
- [x] Prevent duplicate memberships
- [x] Enforce membership-based access to household details
- [x] Implement RSpec model and request tests
- [x] Implement Cucumber acceptance scenarios
- [x] Manually test household creation and invitations

### Follow-up Improvements

- [ ] Add rate limiting for invitation code submissions
- [ ] Support regenerating invitation codes
- [ ] Add invitation expiration if required
- [ ] Improve household management UI and accessibility testing
