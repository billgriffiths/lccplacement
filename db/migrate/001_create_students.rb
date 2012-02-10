class CreateStudents < ActiveRecord::Migration
  def self.up
    create_table :students do |t|
      t.column  :student_number,  :string
      t.column  :first_name,      :string
      t.column  :last_name,       :string
      t.column  :birth_date,      :date
    end
  end

  def self.down
    drop_table :students
  end
end
