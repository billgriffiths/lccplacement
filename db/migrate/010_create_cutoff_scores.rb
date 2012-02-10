class CreateCutoffScores < ActiveRecord::Migration
  def self.up
    create_table :cutoff_scores do |t|
      t.column "test_template_id",         :integer
      t.column "score",                    :float
      t.column "recommendation",           :string
      t.column "alternate_recommendation", :string
      t.column "seq_position",             :integer
      t.column "test_sequence_id",         :integer
      t.column "subsequence_id",           :integer
      t.column "fail_cutoff_score",        :integer
      t.column "pass_cutoff_score",        :integer
    end
  end

  def self.down
    drop_table :cutoff_scores
  end
end
