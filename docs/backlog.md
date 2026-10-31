
### US01 — Household Creation & Invitations

**Status:** Implemented and tested

#### Completed Functionality
- User registration, login, and logout
- Household creation with automatic membership
- Equal permissions for all household members
- Unique invitation code generation
- Joining households using invitation codes
- Duplicate membership prevention
- Membership-based household access restrictions
- Validation and error handling

#### Acceptance Testing

Six Cucumber scenarios have been implemented and passed:

1. Create a new household.
2. Join a household using a valid invitation code.
3. Reject an invalid invitation code.
4. Prevent duplicate household memberships.
5. Require authentication before joining a household.
6. Prevent non-members from accessing household details.

RSpec model and request tests also pass.


#### Future Improvements
- Invitation code regeneration
- Rate limiting invitation code submissions
- Invitation expiration, if required
- Further accessibility and security testing

### US08 — Household Dashboard

**Owner:** Bhaumik Patel

**Status:** Foundation implemented locally; live summaries, peer review, tracker
updates, and production deployment remain outstanding. The full story is not Done.

- [#7 Basic Dashboard Layout](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/issues/7): responsive household dashboard, member list, authenticated navigation, and unavailable-module states.
- [#17 Dashboard Integration](https://github.com/tamu-edu-students/team-water-final-project-Fall-2026-CSCE-606/issues/17): pending real chores, expenses/bills, inventory, and voting integrations.
- [US08 guide](us08-dashboard.md): acceptance criteria, module contracts to confirm, testing, user guide, and proposed sprint tasks.
