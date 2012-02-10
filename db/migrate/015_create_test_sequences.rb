class CreateTestSequences < ActiveRecord::Migration
  def self.up
    create_table :test_sequences do |t|
      t.column "name",                   :string
      t.column "description",            :string
      t.column "initial_recommendation", :text
      t.column "start_test_id",          :integer
      t.column "list_position",          :integer
    end
  end

  def self.down
    drop_table :test_sequences
  end
end
