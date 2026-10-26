
## Household Management System Design

### Architecture

Roommate OS follows the Model-View-Controller (MVC) architecture
provided by Ruby on Rails.

The application uses PostgreSQL for persistent storage and
Active Record for database interactions.

The current implementation includes:

- User: stores registered user information and authentication data.
- Household: represents a shared household created by a user.
- HouseholdMembership: connects users with households and allows
  multiple users to belong to the same household.

### Model Relationships

- A user can belong to multiple households.
- A household can have multiple users.
- HouseholdMembership represents the many-to-many relationship.
- Each household retains a reference to the user who created it.
- Every household has a unique invitation code.

The creator reference is used for identifying who created the
household and does not grant additional permissions.

### Authentication

The application uses Rails session-based authentication.

Passwords are securely hashed through `has_secure_password`
and bcrypt rather than stored as plain text.

Users must log in to access household-related functionality.

### Household Authorization

Household information is accessible only to users who belong
to that household.

Controllers use the current user's household associations
when retrieving household information.

All household members have equal permissions. No administrative
roles are assigned.

### Household Creation

When an authenticated user creates a household:

1. The application validates the household name.
2. A new Household record is created.
3. A unique invitation code is generated.
4. A HouseholdMembership record connects the creator to the household.
5. The user is redirected to the household details page.

Household creation and membership creation occur within a
database transaction to maintain data consistency.

### Invitation Workflow

Users can join existing households using invitation codes.

1. An existing member shares the household's invitation code.
2. Another registered user logs in.
3. The user enters the invitation code.
4. The application looks up the corresponding household.
5. If the code is valid and the user is not already a member,
   a HouseholdMembership record is created.
6. The user is redirected to the household details page.

Invalid codes are rejected, and duplicate memberships are prevented.

### Important Design Decisions

**Equal membership:** The application intentionally avoids admin
and member roles to encourage equal participation among roommates.

**Separate membership model:** HouseholdMembership supports
many-to-many relationships between users and households.

**Unique invitation codes:** Random invitation codes allow
roommates to join households without requiring public household
directories.

**Server-rendered interface:** Rails views and forms support
essential workflows without requiring JavaScript.

**Membership-based authorization:** Household records are
accessed through the logged-in user's memberships to prevent
unauthorized access to private household information.
