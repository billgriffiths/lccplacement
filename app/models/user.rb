class User < ActiveRecord::Base

  ROLE_TYPES = [
    # Displayed     stored in db
    ["staff",         "staff"],
    ["administrator", "administrator"],
    ["proctor",    "proctor"]
  ]
  
  validates_presence_of   :first_name, :last_name, :user_name, :password, :role, :location
  
  validates_uniqueness_of :user_name
  
  attr_accessor :password_confirmation

  validates_confirmation_of :password
  validates_inclusion_of :role, :in => ROLE_TYPES.map {|disp, value| value}
  
  def self.authenticate(user_name, password)
    user = self.find_by_user_name(user_name)
    if user
      if password != user.password
        user = nil
      end
    end
    user
  end
  
end
