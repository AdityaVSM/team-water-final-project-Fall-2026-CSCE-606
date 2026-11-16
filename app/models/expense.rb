class Expense < ApplicationRecord
  belongs_to :household
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user

  validates :title, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validate :due_date_not_before_expense_date

  # Expenses due within the next `days` days, including already-overdue ones.
  scope :due_by, ->(days) { where(due_date: ..days.days.from_now.to_date) }

  # Past due with at least one share still unpaid.
  def overdue?
    due_date.present? && due_date < Date.current &&
      expense_participants.any? { |p| p.user_id != created_by_id && p.payment_status != "paid" }
  end

  # Payments made by others. The creator's own share isn't owed to anyone.
  def paid_by_others?
    expense_participants.where(payment_status: "paid").where.not(user_id: created_by_id).exists?
  end

  PERCENTAGE_TOLERANCE = BigDecimal("0.01")

  RECURRENCES = {
    "weekly"   => "Weekly",
    "biweekly" => "Every 2 weeks",
    "monthly"  => "Monthly",
    "yearly"   => "Yearly"
  }.freeze
  RECURRENCE_LEAD_DAYS = 7    # create each bill this many days before it is due
  MAX_CATCH_UP = 12           # most bills created in one call, if nobody visited for a while

  belongs_to :recurring_parent, class_name: "Expense", optional: true
  has_many :occurrences, class_name: "Expense", foreign_key: :recurring_parent_id,
                        inverse_of: :recurring_parent, dependent: :nullify

  before_validation { self.recurrence = nil if recurrence.blank? }
  validates :recurrence, inclusion: { in: RECURRENCES.keys }, allow_nil: true
  validates :recurrence, absence: true, if: :recurring_parent_id?
  validate :recurrence_requires_due_date
  before_save :schedule_next_occurrence, if: :recurrence_changed?

  # member_ids: optional list of user ids; defaults to the whole household.
  # Always scoped to household members, so outside ids are ignored.
  def split_equally(member_ids = nil)
    users = split_members(member_ids).to_a
    return fail_split("Select at least one member to split with") if users.empty?

    base, extra = amount_in_cents.divmod(users.size)

    # Spread leftover cents one each across the first participants
    # instead of dumping the whole remainder on the last person.
    shares = users.each_with_index.map { |user, i| [ user, base + (i < extra ? 1 : 0) ] }
    create_participants!(shares)
  end

  # splits = { user_id => percentage }
  def split_custom(splits, member_ids = nil)
    users = split_members(member_ids).index_by { |u| u.id.to_s }
    percentages = splits.to_h.transform_keys(&:to_s)
                        .slice(*users.keys)
                        .transform_values { |p| p.to_s.to_d }

    return fail_split("Select at least one member to split with") if percentages.empty?

    if percentages.values.any? { |p| p.negative? || p > 100 }
      return fail_split("Each percentage must be between 0 and 100")
    end

    total = percentages.values.sum
    if (total - 100).abs > PERCENTAGE_TOLERANCE
      return fail_split("Custom split percentages must equal 100% (currently #{total.to_f}%)")
    end

    cents = amount_in_cents
    shares = percentages.map { |id, pct| [ users[id], (cents * pct / 100).round.to_i ] }

    # Last participant absorbs any rounding difference so the total is exact
    allocated = shares[0..-2].sum { |_, c| c }
    shares[-1][1] = cents - allocated

    create_participants!(shares)
  end

  def rescale_shares
    if paid_by_others?
      errors.add(:base, "Amount can't be changed after a payment has been marked as paid")
      return false
    end

    shares = expense_participants.order(:id).to_a
    return true if shares.empty?

    old_cents = shares.map { |p| (p.amount_owed * 100).round.to_i }
    old_total = old_cents.sum
    return true if old_total.zero?

    new_total = amount_in_cents
    new_cents = old_cents.map { |c| (BigDecimal(c) * new_total / old_total).round.to_i }
    new_cents[-1] = new_total - new_cents[0..-2].sum

    transaction do
      shares.zip(new_cents).each { |p, c| p.update!(amount_owed: BigDecimal(c) / 100) }
    end
    true
  end

  # Replaces all shares with whatever the block creates (split_equally / split_custom).
  # Refuses once any share is paid. Call inside a transaction so a failed
  # block rolls the deleted shares back.
  def replace_split
    if paid_by_others?
      errors.add(:base, "The split can't be changed after a payment has been marked as paid")
      return false
    end

    expense_participants.destroy_all
    yield
  end

  def recurring?
    recurrence.present?
  end

  def recurrence_label
    RECURRENCES[recurrence]
  end

  # Creates every bill that is due within the lead window. Safe to call repeatedly:
  # the row lock and the stored next date stop two requests from creating duplicates.
  def generate_due_occurrences!(today = Date.current)
    return 0 unless recurring?

    created = 0
    with_lock do
      while recurring? && recurrence_next_on && recurrence_next_on <= today + RECURRENCE_LEAD_DAYS &&
            created < MAX_CATCH_UP
        create_occurrence!(recurrence_next_on)
        update_column(:recurrence_next_on, next_due_after(recurrence_next_on))
        created += 1
      end
    end
    created
  end

  # scope can be Expense or a household's expenses
  def self.generate_recurring(scope = Expense)
    scope.where.not(recurrence: nil)
        .where(recurrence_next_on: ..(Date.current + RECURRENCE_LEAD_DAYS))
        .to_a.sum(&:generate_due_occurrences!)
  end

  private

  def recurrence_requires_due_date
    errors.add(:due_date, "is required for a recurring expense") if recurring? && due_date.blank?
  end

  def schedule_next_occurrence
    self.recurrence_next_on = (recurring? && due_date) ? next_due_after(due_date) : nil
  end

  # Monthly and yearly steps keep the original day of month, so Jan 31 goes to
  # Feb 28, then back to Mar 31 instead of drifting to the 28th.
  def next_due_after(date)
    case recurrence
    when "weekly"   then date + 7
    when "biweekly" then date + 14
    when "monthly"  then step_months(date, 1)
    when "yearly"   then step_months(date, 12)
    end
  end

  def step_months(date, months)
    target = date >> months
    day = [due_date.day, Time.days_in_month(target.month, target.year)].min
    Date.new(target.year, target.month, day)
  end

  def create_occurrence!(due)
    copy = occurrences.create!(
      household: household, created_by: created_by,
      title: title, description: description, amount: amount,
      expense_date: due, due_date: due
    )
    expense_participants.each do |share|
      copy.expense_participants.create!(user_id: share.user_id,
                                        amount_owed: share.amount_owed,
                                        payment_status: "pending")
    end
    copy
  end

  def due_date_not_before_expense_date
    return if due_date.blank? || expense_date.blank?
    errors.add(:due_date, "can't be before the expense date") if due_date < expense_date
  end

  def split_members(member_ids)
    scope = household.users
    member_ids.nil? ? scope : scope.where(id: member_ids)
  end

  def amount_in_cents
    (amount * 100).round.to_i
  end

  def create_participants!(shares)
    transaction do
      shares.each do |user, cents|
        expense_participants.create!(
          user: user,
          amount_owed: BigDecimal(cents) / 100,
          payment_status: "pending"
        )
      end
    end
    true
  end

  def fail_split(message)
    errors.add(:base, message)
    false
  end
end
