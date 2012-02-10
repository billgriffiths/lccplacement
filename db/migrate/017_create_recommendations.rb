class CreateRecommendations < ActiveRecord::Migration
  def self.up
    create_table :recommendations do |t|
      t.column :key_vector, :string
      t.column :rec,        :text
      t.column :tally,      :integer
    end
  end

  def self.down
    drop_table :recommendations
  end
end
