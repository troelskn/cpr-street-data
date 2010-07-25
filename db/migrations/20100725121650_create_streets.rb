class CreateStreets < ActiveRecord::Migration
  def self.up
    create_table :streets do |t|
      t.string :street_name, :limit => 40
      t.string :zip_code, :limit => 4
      t.string :city_name, :limit => 20
      t.integer :uuid
    end
    add_index :streets, :street_name
    add_index :streets, :uuid, :unique => true
  end

  def self.down
    remove_table :streets
  end
end
