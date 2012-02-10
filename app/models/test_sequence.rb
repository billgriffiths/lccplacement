class TestSequence < ActiveRecord::Base
  
  has_many    :cutoff_scores
  
  validates_presence_of   :name, :description
  validates_uniqueness_of :name
  
end
