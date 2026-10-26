require "rails_helper"

RSpec.describe CalendarService do
  let(:creator) { User.create!(name: "Aditi", email: "aditi@example.com") }
  let(:household) do
    Household.create!(name: "Apartment 101", creator: creator).tap do |record|
      HouseholdMembership.create!(household: record, user: creator, role: "admin")
    end
  end

  def create_event(attributes = {})
    household.events.create!(
      {
        creator: creator,
        name: "House meeting",
        start_timestamp: Time.zone.parse("2026-11-03 18:00"),
        end_timestamp: Time.zone.parse("2026-11-03 19:00"),
        recurring: "DAILY"
      }.merge(attributes)
    )
  end

  it "expands daily occurrences and preserves their original start" do
    event = create_event

    occurrences = described_class.new.events_for(
      household,
      from: Time.zone.parse("2026-11-04 00:00"),
      to: Time.zone.parse("2026-11-05 23:59")
    )

    expect(occurrences.map(&:original_start)).to eq(
      [Time.zone.parse("2026-11-04 18:00"), Time.zone.parse("2026-11-05 18:00")]
    )
    expect(occurrences.map(&:event_id).uniq).to eq([event.id])
  end

  it "applies occurrence changes and omits cancelled occurrences" do
    event = create_event
    moved_start = Time.zone.parse("2026-11-04 20:00")
    event.event_exceptions.create!(
      original_start: Time.zone.parse("2026-11-04 18:00"),
      start_timestamp: moved_start,
      end_timestamp: moved_start + 1.hour
    )
    event.event_exceptions.create!(
      original_start: Time.zone.parse("2026-11-05 18:00"),
      is_cancelled: true
    )

    occurrences = described_class.new.events_for(
      household,
      from: Time.zone.parse("2026-11-04 00:00"),
      to: Time.zone.parse("2026-11-05 23:59")
    )

    expect(occurrences.map(&:start_timestamp)).to eq([moved_start])
    expect(occurrences.first.original_start).to eq(Time.zone.parse("2026-11-04 18:00"))
  end
end
