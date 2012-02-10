class AddHistogramColumns < ActiveRecord::Migration
  def self.up
    add_column :template_versions, :histogram,      :text
    add_column :template_versions, :number_scores,  :integer
  end

  def self.down
    remove_column :template_versions, :histogram
    remove_column :template_versions, :number_scores
  end
end
