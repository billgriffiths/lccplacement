class Student < ActiveRecord::Base

  has_many  :test_results
  has_many  :test_sessions
  
  validates_presence_of   :first_name, :last_name, :student_number, :birth_date
  
  validates_format_of     :student_number, :with => /^L\d{8}$/
  
  validates_uniqueness_of :student_number
  
  def add_test_result(test_result)
    @test_result = TestResult.find(test_result)
    test_results << @test_result
  end

  def add_test_session(test_session)
    @test_session = TestSession.find(test_session)
    test_sessions << @test_session
  end

  def validate
    first_name.strip!
    last_name.strip!
  end
end
