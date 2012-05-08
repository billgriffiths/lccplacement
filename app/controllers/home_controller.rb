class HomeController < ApplicationController
  def index
    session[:session_id]
  end

end
