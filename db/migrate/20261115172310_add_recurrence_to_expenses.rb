class AddRecurrenceToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :recurrence, :string          # weekly, biweekly, monthly, yearly, or NULL
    add_column :expenses, :recurrence_next_on, :date    # next due date waiting to be created
    add_reference :expenses, :recurring_parent,
                  foreign_key: { to_table: :expenses, on_delete: :nullify }, null: true
    add_index :expenses, :recurrence_next_on
  end
end