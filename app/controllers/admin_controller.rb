class AdminController < ApplicationController

  layout "admin"
  
  before_filter :authorize_access, :except => :login

  def index
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def try_test
    if request.post?
      @test = TestTemplate.find(params[:test])
      @test_version = TemplateVersion.find(@test.template_version_id)
      @test_list = TestSessionController.generate_test_form(@test_version.template)
      @resource = @test_list[3]
      @test_list.delete_at(3)
      session[:test_list] = @test_list
      session[:resource] = @resource
      @answers = nil
      redirect_to( :action => 'show_test_try')
    end
  end
  
  def show_test_try
    @resource = session[:resource]
    @test_list = session[:test_list]
    @n = @test_list[2].to_i
    if @answers.nil?
      @answers = Answers.new
      @answers.items = Array.new(@n) {|i| (i+1).to_s}
    end
    session[:answers] = @answers
    session[:n] = @n
  end

  def score_try
      require 'open-uri'
      require 'pp'
      answers = session[:answers].items
      @test_list = session[:test_list]
      @n = session[:n]
      n = @test_list.length
      choices = []
      l = "A"
      26.times do 
      	 choices << l
         l = l.succ
      end
      score = 0
      @user_answers = []
      1.upto(@n) {|i| 
        if params.has_key?(i.to_s)
          @user_answers[i]=params[i.to_s]
        else
          @user_answers[i]=""
        end
      }
      i = 0
      @key = []
      @missed_questions = []
      @test_list.each do |p|
        code = p[p.length-2,2]
        if code == "/m"
          i += 1
          folder = p.split("/")[1]
          problem = p.split("/")[2]
          if folder == "PEmultchoiceimages"
            problem += ".pedr"
          elsif folder == "PEXmultchoiceimages"
            problem += ".pedx"
          elsif folder == "5multchoiceimages"
            problem += ".5jpg"
          else
            problem += ".jpg"
          end
          keystring = p.split("/")[3].split(".")[0].gsub(",","")
          number_choices = keystring.length
          key_answer = choices[keystring.index("1")]
          @key << key_answer
#          temp_answer = answers[i-1].split(" ")
#          temp_answer.delete_at(0)
#          user_answer = temp_answer.to_s
          user_answer = @user_answers[i]
          if @user_answers[i] == nil 
            user_answer = ""
          end
          if user_answer == key_answer
            score += 1
          else
            @missed_questions << i.to_s + "<*>" + user_answer + "<*>" + key_answer +"<*>" + p
          end
        elsif code == "/f"
          i += 1
          temp_answer = answers[i-1].split(" ")
          temp_answer.delete_at(0)
          user_answer = temp_answer.to_s
          parray = p.split("?")[1].split("&")
          open("http://math.lanecc.edu/getproblemanswers?problem=#{parray[0].split("=")[1]}&seed=#{parray[3].split("=")[1]}&useranswer=#{user_answer}") do |f|
            keystring = f.gets
          end
          keyarray = keystring.split(";<br>")
          key_answer = keyarray[0]
          @key << key_answer
          @user_answers << user_answer
          if keyarray[1].to_i == 1
            score += 1
          else
            @missed_questions << i.to_s + "<*>" + user_answer + "<*>" + key_answer +"<*>" + p
          end
        end
      end
      @score = (10000*score/1.0/i).round/100.0
  end

  def get_student_record
    session[:student_action] = "show_record"
    redirect_to(:controller => 'students', :action => 'choose_student')
  end

  def authorize
#    @student_pages, @students = paginate :students, :per_page => 10
    session[:student_action] = "authorize_session"
    redirect_to(:controller => 'students', :action => 'choose_student')
  end

  def authorize_reentry
    session[:student_action] = "authorize_reentry"
    redirect_to(:controller => 'students', :action => 'choose_student')
  end

  def student_resume_test
    redirect_to(:controller => 'test_session', :action => 'student_resume_test')
  end

  def retrieve_test
#    @student_pages, @students = paginate :students, :per_page => 10
    session[:student_action] = "retrieve_test"
    redirect_to(:controller => 'students', :action => 'choose_student')
  end

 def add_user
    @user = User.new(params[:user])
    if request.post? and @user.save
      flash.now[:notice] = "User #{@user.user_name} created"
    end
  end

  def list_users
    @users = User.find(:all, :order => 'last_name')
#    @user_pages, @users = paginate :users, :per_page => 10
  end

  def show_user
    @user = User.find(params[:id])
  end

  def create_user
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list_users'
    else
      render :action => 'new_user'
    end
  end

  def new_user
    @user = User.new
  end

  def edit_user
    @user = User.find(params[:id])
  end

  def update_user
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show_user', :id => @user
    else
      render :action => 'list_user'
    end
  end

  def destroy_user
    User.find(params[:id]).destroy
    redirect_to :action => 'list_users'
  end

  def login
    session[:user_id] = nil
    session[:user_role] = nil
    session[:location] = nil
    if request.post?
      user = User.authenticate(params[:user_name], params[:password])
      if user
        session[:user_id] = user.id
        session[:user_role] = user.role
        url = session[:orginal_url]
        session[:orginal_url] = nil
        session[:location] = user.location
        redirect_to(url || {:action => "index"})
      else
        flash[:notice] = "Invalid user name or password"
      end
    end
  end

  def logout
    session[:user_id] = nil
    session[:user_role] = nil
    session[:original_url] = nil
    session[:location] = nil
    flash[:notice] = "logged out"
    redirect_to(:action  => "login")
  end

  def delete_user
    if request.post?
      user = User.find(params[:id])
      begin
        user.destroy
        flash[:notice] = "User #{user.name} deleted"
      rescue Exception => e
        flash[:notice] = e.message
      end
    end
    redirect_to(:action  => :list_users)
  end

  def upload_problem

  end

end
