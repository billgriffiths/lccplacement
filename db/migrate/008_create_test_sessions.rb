class CreateTestSessions < ActiveRecord::Migration
  def self.up
    create_table :test_sessions do |t|
      t.column "status",           :string
      t.column "start_time",       :datetime
      t.column "student_id",       :integer
      t.column "location",         :string
      t.column "test_sequence_id", :integer
      t.column "start_test_id",    :integer
      t.column "parent_session",   :integer
      t.column "final_test",       :integer
      t.column "final_score",      :float
      t.column "processed",        :datetime
    end
  end

  def self.down
    drop_table :test_sessions
  end
end
