class StudentsController < ApplicationController

  layout "admin"
 
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def choose_student
   if request.post?
     if not params[:letter].blank?
       @students = Student.find(:all, :conditions => ["last_name like ?",params[:letter]+"%"], :order => 'last_name, first_name')      
     else
       @students = Student.find(:all, :conditions => ["last_name like ? and first_name like ? and student_number like ?",params[:last_name]+"%",params[:first_name]+"%",params[:student_number]+"%"], :order => 'last_name, first_name')
     end
     if @students.empty?
       user = User.find(session[:user_id])
       if user.role == "instructor"
         flash[:notice] = "No matching students found for instructor #{user.last_name}."
       else
         flash[:notice] = "No matching students found."
       end
     end
   end
  end

  def show_record
    #   session[:student_action] = nil
    @student = Student.find(params[:id])
    @test_results = TestResult.find(:all, :conditions => ["student_id = ?", @student.id], :order => 'start_time desc')
    @test_sessions = TestSession.find(:all, :conditions => ["student_id = ? and status = 'finished'",@student.id], :order => 'start_time desc')
  end
  
  def StudentsController.get_test_vector h
    tests = ["I","H","G","F","E2","E1","D","C","B","A"]
    test_vector = []
    for t in tests
      if h[t] == "empty"
        test_vector << "  "
      else
        if h[t].length >1
          test_vector << h[t]
        elsif h[t].length == 1
          test_vector << " "+h[t]
        else 
          test_vector << "  "
        end
      end
    end
    return test_vector
  end

  def authorize
   @student = Student.find(params[:id])
   session[:student_action] = nil
  end

  def authorize_session
   @student = Student.find(params[:id])
   session[:student_action] = nil
  end

  def authorize_reentry
   @student = Student.find(params[:id])
   session[:student_action] = nil
  end

  def authorize_resume_test
    @test_result = TestResult.find(params[:id])
    @student = Student.find(@test_result.student_id)
    TestSession.find(:all, :conditions => ["status != ? and student_id = ?",'finished',@test_result.student_id]).each do |r|
       r.status = "finished"
       r.save
    end
    if request.post?
      @test_result.update_attribute(:status,"authorized")
      @test = TestTemplate.find(TemplateVersion.find(@test_result.template_version_id).test_template_id)
      test_session = TestSession.find(@test_result.test_session_id)
      test_session.status = "authorized"
      test_session.start_time = Time.now + params[:time_limit].to_i*60
      cutoff_score = CutoffScore.find(:first, :conditions =>["test_template_id = ? and test_sequence_id = ?",@test.id,test_session.test_sequence_id])
      test_session.start_test_id = cutoff_score.id
      test_session.save
      flash[:notice] = "#{@student.first_name} #{@student.last_name} was successfully authorized to resume #{@test.description}."
      render :action => 'authorize_reentry_test'
    end
  end

  def authorize_reentry_test
   if request.post?
     test_results = TestResult.find(params[:id])
     test_results.status = "authorized"
     test_results.save
     test_session = TestSession.find(test_results.test_session_id)
     test_session.status = "authorized"
     test_session.start_time = Time.now + params[:time_limit].to_i*60
     test_session.save
     @student = Student.find(test_results.student_id)
     @test = TestTemplate.find(TemplateVersion.find(@test_results.template_version_id).test_template_id)
      flash[:notice] = "#{@student.first_name} #{@student.last_name} was successfully authorized to resume #{@test.description}."
   end
  end

  def authorize_test
   @student = Student.find(params[:student])
   @test = TestTemplate.find(params[:test])
   TestResult.destroy_all("status = 'authorized' and student_id = #{params[:student]}")
   test_result = TestResult.new
   test_result.status = 'authorized'
   test_result.student_id = @student
   test_result.template_version_id = @test
   test_result.start_time = Time.now + params[:time_limit].to_i*60
   test_result.save
   @student.add_test_result(test_result)
   @student.save
   @message = "Test #{@test.name} was successfully authorized for #{@student.first_name} #{@student.last_name}."
  end

  def authorize_testing_session
    @student = Student.find(params[:student])
    if !params[:test_sequence_id].blank?
       TestSession.find(:all, :conditions => ["status != ? and student_id = ?",'finished',params[:student]]).each do |r|
          r.status = "terminated"
          r.save
       end
       @test_session = TestSession.new
       @test_session.status = 'authorized'
       @test_session.student_id = @student
       @test_session.start_time = Time.now + params[:time_limit].to_i*60
       @test_session.test_sequence_id = params[:test_sequence_id]
       # get authorized cutoff_score for this session; this is the starting test or sequence
       @test_session.start_test_id =  params[:test_session]["start_test_id #{@test_session.test_sequence_id}"]
       @test_session.location =  session[:location]
       if @test_session.save
         @student.add_test_session(@test_session)
         @student.save
         flash[:notice] = "Test session was successfully authorized for #{@student.first_name} #{@student.last_name}."
       else
         flash[:notice] = "Unable to save test session for #{@student.first_name} #{@student.last_name}."
       end
     else
       flash[:notice] = "You must select a test sequence."
       render :action => 'authorize_session'
     end
  end

  def pre_authorize_testing_session
    @student = Student.find(params[:student])
    @test_session = TestSession.new
    @test_session.status = 'authorized'
    @test_session.student_id = @student
    @test_session.start_time = Time.now + params[:time_limit].to_i*60
    @test_session.test_sequence_id = -1 # no sequence has been assigned
#    @test_session.start_test_id blank indicates no starting cutoff score has been assigned
    @test_session.location = session[:location]
    if @test_session.save
      @student.add_test_session(@test_session)
      @student.save
      flash[:notice] = "Test session was successfully authorized for #{@student.first_name} #{@student.last_name}."
    else
      flash[:notice] = "Unable to save test session for #{@student.first_name} #{@student.last_name}."
    end
  end

  def show_test
    if @answers.nil?
      @answers = Answers.new
    end
    @test_results = TestResult.find(params[:test_results])
    @test = TemplateVersion.find(@test_results.template_version_id)
    @test_list = @test_results.test_items.split("<*>")
    @n = @test_list[2].to_i
    @answers.items = @test_results.answers.split("<*>")
  end

  def list
#    @student_pages, @students = paginate :students, :per_page => 10
    @students = Student.find(params[:all])
  end

  def show
    @student = Student.find(params[:id])
  end

  def new
    @student = Student.new
  end

  def create_session
    @student = Student.find(:first, :conditions => ["student_number != ? and first_name = ? and last_name = ? and birth_date = ?",params[:student]])
    if !@student
      @student = Student.new(params[:student])
      if !@student.save
        flash[:notice] = "Student data conflicts with database records. #{@student.student_number} #{@student.first_name} #{@student.last_name} #{@student.birth_date}."
        redirect_to :controller => 'test_session', :action => 'student_login2'
      end
    end
    @test_session = TestSession.new
    @test_session.status = 'authorized'
    @test_session.student_id = @student
    @test_session.start_time = Time.now + 24*60*60
    @test_session.test_sequence_id = -1 #sequence is none
#   @test_session.start_test_id blank indicates no start cutoff score has been assigned
    @test_session.location = session[:location]
    if @test_session.save
      @student.add_test_session(@test_session)
      @student.save
      flash[:notice] = "Test session was successfully authorized for #{@student.first_name} #{@student.last_name} #{@student.student_number}."
    else
      flash[:notice] = "Unable to save test session for #{@student.first_name} #{@student.last_name}."
    end
    redirect_to :controller => 'student', :action => 'student_session'
  end

  def create
    @student = Student.new(params[:student])
    if @student.save
      @test_session = TestSession.new
      @test_session.status = 'authorized'
      @test_session.student_id = @student
      @test_session.start_time = Time.now + 24*60*60
      @test_session.test_sequence_id = -1 #sequence is none
#      @test_session.start_test_id blank indicates no start cutoff score has been assigned
      @test_session.location = session[:location]
      if @test_session.save
        @student.add_test_session(@test_session)
        @student.save
        flash[:notice] = "Test session was successfully authorized for #{@student.first_name} #{@student.last_name} #{@student.student_number}."
      else
        flash[:notice] = "Unable to save test session for #{@student.first_name} #{@student.last_name}."
      end
      redirect_to :action => 'show_record', :id => Student.find(@student)
    else
      render :action => 'new'
    end
  end

  def edit
    @student = Student.find(params[:id])
  end

  def update
    @student = Student.find(params[:id])
    if @student.update_attributes(params[:student])
      flash[:notice] = 'Student was successfully updated.'
      redirect_to :action => 'show', :id => @student
    else
      render :action => 'edit'
    end
  end

  def destroy
    #destroy all data arising from this student
    @student = Student.find(params[:id])
    @student.test_results.destroy_all
    @student.test_sessions.destroy_all
    @student.destroy
    redirect_to :action => 'list'
  end
end
