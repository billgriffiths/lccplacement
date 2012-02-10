class CreateTemplateVersions < ActiveRecord::Migration
  def self.up
    create_table :template_versions do |t|
      t.column :version, :integer
      t.column :template, :text
      t.column :test_template_id, :integer
    end
  end

  def self.down
    drop_table :template_versions
  end
end
