class CreateTestTemplates < ActiveRecord::Migration
  def self.up
    create_table :test_templates do |t|
      t.column "name",                :string
      t.column "template_version_id", :integer
      t.column "description",         :string
      t.column "color",               :string,  :limit => 7
      t.column "code",                :string,  :limit => 4
      t.column "status",              :string,  :limit => 8, :default => "active"
    end
  end

  def self.down
    drop_table :test_templates
  end
end
