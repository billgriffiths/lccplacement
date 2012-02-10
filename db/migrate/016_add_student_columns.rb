class AddStudentColumns < ActiveRecord::Migration
  def self.up
    add_column :students, :test_vector, :string
    add_column :students, :last_date,   :datetime
  end

  def self.down
    remove_column :students, :test_vector
    remove_column :students, :last_date
  end
end
