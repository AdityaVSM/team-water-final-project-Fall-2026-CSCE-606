class AddVaultAndDetailsToHouseholds < ActiveRecord::Migration[8.1]
  def change
    add_column :households, :wifi_ssid, :string
    add_column :households, :wifi_password, :string
    add_column :households, :trash_pickup, :string
    add_column :households, :landlord_hotline, :string
    add_column :households, :apartment_name, :string
    add_column :households, :mailing_address, :text
    add_column :households, :map_link, :string
  end
end
