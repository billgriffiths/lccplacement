class Recommendation < ActiveRecord::Base
  
  validates_presence_of   :key_vector, :rec, :tally
  
end
