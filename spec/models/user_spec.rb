require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with a name and email" do
      user = User.new(
        name: "Aditi",
        email: "aditi@example.com"
      )

      expect(user).to be_valid
    end

    it "requires a name" do
      user = User.new(email: "aditi@example.com")

      expect(user).not_to be_valid
    end

    it "requires an email" do
      user = User.new(name: "Aditi")

      expect(user).not_to be_valid
    end

    it "does not allow duplicate emails" do
      User.create!(
        name: "Aditi",
        email: "aditi@example.com"
      )

      duplicate = User.new(
        name: "Another User",
        email: "aditi@example.com"
      )

      expect(duplicate).not_to be_valid
    end
  end
end