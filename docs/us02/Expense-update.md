## Expense updates and Heroku deployment

### Expense changes
- **Recurring expenses:** an expense can repeat weekly, every 2 weeks, monthly, or yearly. It needs a due date. New bills are created about a week before each due date with the same split, and monthly bills keep their day of the month after short months. Bills are created when the expense or dashboard pages load, so no background worker is needed.
- **Edit split and members:** the edit form can keep the current split, re-split equally, or use custom percentages. The split locks once anyone other than the creator has paid.
- **Redirects:** creating an expense opens its page. Deleting an expense, or marking a payment with no referer, goes to the expenses index.
- **Dashboard:** the Bills & balances card links to the expenses index, and the separate add and view links are gone.
- **Form fixes:** custom splits now work on the new expense form, and the member list no longer comes back empty on create.

### Heroku deployment
- Added a `Procfile` with a `web` process and a `release` phase that runs `db:migrate` on each deploy
- The Render setup (`render.yaml`, `bin/render-build.sh`) is unchanged, and both platforms use the single `DATABASE_URL` config
- Heroku setup: create the app and the Postgres add-on, then run `heroku config:set SECRET_KEY_BASE=$(bin/rails secret)` and push

### Database
- One new migration adds `recurrence`, `recurrence_next_on`, and `recurring_parent_id` to `expenses`
- Run `bin/rails db:migrate`. Existing expenses are unaffected

### Notes for reviewers
- The dashboard controller now calls `Expense.generate_recurring` so new bills show up there. That file belongs to another teammate, so please check it
- Editing a recurring expense's amount or split is locked once someone has paid it, so changing future bills means stopping the repeat and creating a new one
- Render and Heroku use separate databases

### Testing
- Added model specs for recurrence and controller specs for saving and rejecting recurring expenses
- Updated specs that expected the old redirects