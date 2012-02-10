class Student < ActiveRecord::Base

  has_many  :test_results
  has_many  :test_sessions
  
  validates_presence_of   :first_name, :last_name, :student_number
  
  validates_format_of     :student_number, :with => /^820\d{6}$/
  
  validates_uniqueness_of :student_number
  
  def add_test_result(test_result)
    @test_result = TestResult.find(test_result)
    test_results << @test_result
  end

  def add_test_session(test_session)
    @test_session = TestSession.find(test_session)
    test_sessions << @test_session
  end

end
