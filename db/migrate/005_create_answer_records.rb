class CreateAnswerRecords < ActiveRecord::Migration
  def self.up
    create_table :answer_records do |t|
      t.column "problem",             :string
      t.column "decoded_answer",      :string
      t.column "start_time",          :datetime
      t.column "test_result_id",      :integer
      t.column "template_version_id", :integer
      t.column "section",             :string
      t.column "choices",             :integer
    end
  end

  def self.down
    drop_table :answer_records
  end
end
