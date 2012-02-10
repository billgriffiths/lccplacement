# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_placement_session_id'
  
  before_filter :authorize_access, :except => [:get_test, :get_next_test, :find_next_test_in_sequence, :show_test, 
    :score, :student_login2, :student_intro, :student_logout, :staff_login, :create_session, 
    :authorize_testing_session, :get_subsession_results, :resume, :student_resume_test, :authorize_resume_test, 
    :session_results, :get_sequence, :update_answers, :individual_tests, :get_start_test, :get_individual_test]
  
#  layout proc{ |c| c.request.xhr? ? false : "application" }

  private

  def authorize_access
    return if self.controller_name == 'test_session'
    unless User.find_by_id(session[:user_id])
      session[:orginal_url] = request.request_uri
#      flash[:notice] = "Please Log In"
      redirect_to(:controller => "admin", :action => "login") and return false
    end
  end
end
