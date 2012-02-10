class TestSession < ActiveRecord::Base
  belongs_to  :student
  belongs_to  :test_sequence
  has_many    :test_results

  validates_presence_of   :student_id, :test_sequence_id, :location, :parent_session, :processed
end
