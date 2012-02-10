class TestResult < ActiveRecord::Base

  belongs_to  :student
  belongs_to  :template_version
  belongs_to  :test_session
  has_many    :answer_records

  validates_presence_of   :status, :start_time, :student_id, :template_version_id, :test_session_id
  
  def cutoff_score
    test_template_id = TemplateVersion.find(template_version_id).test_template_id
    test_sequence_id = TestSession.find(test_session_id).test_sequence_id
    cutoff_score = CutoffScore.find(:first, :conditions => ["test_sequence_id = ? and test_template_id = ?",test_sequence_id,test_template_id])
  end

end
