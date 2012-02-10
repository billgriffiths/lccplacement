class CreateProcedures < ActiveRecord::Migration
  def self.up
    create_table :procedures do |t|
      t.column :name, :string
      t.column :text, :text
      t.column :description, :string
    end
  end

  def self.down
    drop_table :procedures
  end
end
