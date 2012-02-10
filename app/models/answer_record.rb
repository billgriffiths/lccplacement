class AnswerRecord < ActiveRecord::Base

  belongs_to  :template_version
  belongs_to  :test_result
  
  validates_presence_of   :problem, :decoded_answer, :start_time, :template_version, :test_result
  
end
