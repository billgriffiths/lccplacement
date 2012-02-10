class CreateTestResults < ActiveRecord::Migration
  def self.up
    create_table :test_results do |t|
      t.column "answers",             :string
      t.column "test_items",          :text
      t.column "score",               :float
      t.column "raw_score",           :integer
      t.column "status",              :string
      t.column "start_time",          :datetime
      t.column "student_id",          :integer
      t.column "template_version_id", :integer
      t.column "test_session_id",     :string
      t.column "cutoff_score_id",     :integer
    end
  end

  def self.down
    drop_table :test_results
  end
end
