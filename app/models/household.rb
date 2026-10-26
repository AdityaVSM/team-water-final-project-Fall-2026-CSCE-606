class Household < ApplicationRecord
  belongs_to :creator, class_name: "User"

  has_many :household_memberships, dependent: :destroy
  has_many :users, through: :household_memberships
  has_many :events, dependent: :destroy

  validates :name, presence: true
end