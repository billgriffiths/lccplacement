class TestResultsController < ApplicationController

  layout "admin"
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    the_date = Date.today + 1
    yesterday = Date.today - 1
    @test_results = TestResult.find(:all, :conditions => [" start_time >= ? and start_time <= ?",yesterday,the_date], :limit => 100, :order => 'start_time desc')
    @dates = "#{yesterday.strftime('%m/%d/%Y')} to #{the_date.strftime('%m/%d/%Y')}."
    if @test_results.length == 0
      flash[:notice] = "No recent tests."
    else
      flash[:notice] = nil
    end
  end

  def show
    @test_result = TestResult.find(params[:id])
  end

  def new
    @test_result = TestResult.new
  end

  def create
    @test_result = TestResult.new(params[:test_result])
    if @test_result.save
      flash[:notice] = 'TestResult was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @test_result = TestResult.find(params[:id])
  end

  def update
    @test_result = TestResult.find(params[:id])
    if @test_result.update_attributes(params[:test_result])
      flash[:notice] = 'TestResult was successfully updated.'
      redirect_to :action => 'show', :id => @test_result
    else
      render :action => 'edit'
    end
  end

  def destroy
    test_result = TestResult.find(params[:id])
    test_result.answer_records.destroy_all
    test_result.destroy
    redirect_to :action => 'list'
  end

  def scores_by_date
    flash[:notice] = "Please limit the period encompassed by the dates you choose to a relatively short period"+
    " or run this report during off hours." +
    " This report makes intensive use of the database and no others will be able to perform testing system" +
    " operations while this report is being produced."
  end

  def summary_by_date
    flash[:notice] = "Please limit the period encompassed by the dates you choose to a relatively short period"+
    " or run this report during off hours." +
    " This report makes intensive use of the database and no others will be able to perform testing system" +
    " operations while this report is being produced."
  end

  def recommendations_by_date

  end

  def daily_results

  end

  def Banner_report
    flash[:notice] = nil

  end
  
  def show_recommendations
    sessions = TestSession.find(:all, :conditions => ["status = ? and id = ?","finished",15371])
    @test_lists = []
    for s in sessions
      test_list = TestResult.find(:all, :conditions => ["test_session_id = ?", s.id])
      h = Hash.new("empty")
      for t in test_list
        test_id = TemplateVersion.find(t.template_version_id)
        h[TestTemplate.find(test_id).name] = t.raw_score.to_s
      end
      @test_lists << StudentsController.get_test_vector(h).to_s + TestSessionController.get_recommendation(s.id)
    end
    @test_lists.sort!
  end

  def get_recommendations_by_date
    if request.post?
      @course = params["Course"]
#      start_time = Time.local(params["start_date"]["year"],params["start_date"]["month"],params["start_date"]["day"])
#      end_time = Time.local(params["end_date"]["year"],params["end_date"]["month"],params["end_date"]["day"])
#      next_day = end_time.tomorrow
#      @test_results = TestResult.find(:all, :conditions => ["start_time >= ? and start_time < ?",start_time,next_day])
#      @dates = "#{start_time.strftime('%m/%d/%Y')} to #{end_time.strftime('%m/%d/%Y')}."
      @recommendations = Recommendation.find(:all, :conditions => ["rec like ?","%#{@course}%"]).sort_by {|r| [r.key_vector]}
      if @recommendations.empty?
        flash[:notice] = "No recommendation records for course math #{@course}."
      else
        flash[:notice] = nil
        @tests = ["I","H","G","F","E2","E1","D","C","B","A"]
        o = {"A"=>18,"B"=>16,"C"=>14,"D"=>12,"E1"=>10,"E2"=>8,"F"=>6,"G"=>4,"H"=>2,"I"=>0}
        @l = {"A"=>10,"B"=>10,"C"=>10,"D"=>10,"E1"=>10,"E2"=>10,"F"=>20,"G"=>20,"H"=>10,"I"=>10}
        @h = {}
        for t in @tests
          @h[t] = {}
          for i in 0..@l[t]
            @h[t][i] = 0
          end
        end
        for r in @recommendations
          v = r.key_vector
          for t in @tests
            score = v.slice(o[t]..o[t]+1)
            if score != "  "
              @h[t][score.to_i] += r.tally
            end
          end
        end
      end
    end
  end

  def get_test_records_by_date
    if request.post?
      @location = params["TestSession"]["location"]
      start_time = Time.local(params["start_date"]["year"],params["start_date"]["month"],params["start_date"]["day"])
      end_time = Time.local(params["end_date"]["year"],params["end_date"]["month"],params["end_date"]["day"])
      next_day = end_time.tomorrow
      @test_results = TestResult.find(:all, :conditions => ["start_time >= ? and start_time < ?",start_time,next_day], :order => 'student_id,start_time desc')
      @dates = "#{start_time.strftime('%m/%d/%Y')} to #{end_time.strftime('%m/%d/%Y')}."
      if @test_results.empty?
        flash[:notice] = "No tests between the dates #{start_time.strftime('%m/%d/%Y')} and #{end_time.strftime('%m/%d/%Y')}."
      else
        flash[:notice] = nil
      end
    end
  end

  def get_daily_results
    if request.post?
      @location = params["TestSession"]["location"]
      the_date = Time.local(params["the_date"]["year"],params["the_date"]["month"],params["the_date"]["day"])
      next_day = the_date.tomorrow
      @test_results = TestResult.find(:all, :conditions => ["start_time >= ? and start_time < ?",the_date,next_day], :order => 'student_id')
      @dates = "#{the_date.strftime('%m/%d/%Y')}."
      if @test_results.empty?
        flash[:notice] = "No tests for #{the_date.strftime('%m/%d/%Y')}."
      else
        flash[:notice] = nil
      end
      render :action => 'get_test_records_by_date'
    end
  end
 
  def get_test_summary_by_date
    flash[:notice] = nil
    if request.post?
      start_time = Time.local(params["start_date"]["year"],params["start_date"]["month"],params["start_date"]["day"])
      end_time = Time.local(params["end_date"]["year"],params["end_date"]["month"],params["end_date"]["day"])
#      next_day = end_time.tomorrow
      the_date = start_time
      @total_test_results = 0
      @test_results = []
      while the_date <= end_time
        the_next_date = the_date.tomorrow
        count = TestResult.count(:conditions => ["start_time >= ? and start_time < ?",the_date,the_next_date])
        @test_results << ["#{the_date.strftime('%m/%d/%Y')}",count]
        @total_test_results += count
        the_date = the_next_date
      end
      @dates = "#{start_time.strftime('%m/%d/%Y')} to #{end_time.strftime('%m/%d/%Y')}."
#      @total_test_results = TestResult.count(:conditions => ["start_time >= ? and start_time < ?",start_time,next_day])
    end
  end

  def pad_field(field_data,field_length)
    return field_data << " "*(field_length - field_data.length)
  end

  def get_Banner_results_by_date
    if request.post?
      start_time = Time.local(params["start_date"]["year"],params["start_date"]["month"],params["start_date"]["day"])
      end_time = Time.local(params["end_date"]["year"],params["end_date"]["month"],params["end_date"]["day"])
      next_day = end_time.tomorrow
      @start_time = start_time.strftime('%Y/%m/%d')
      @end_time = end_time.strftime('%Y/%m/%d')
      @next_day = end_time.tomorrow.strftime('%Y/%m/%d')
      @dates = "#{start_time.strftime('%m/%d/%Y')} to #{end_time.strftime('%m/%d/%Y')}."
      @test_results = TestResult.find(:all, :conditions => ["status = 'finished' and start_time >= ? and start_time < ?",start_time,next_day], :order => 'student_id,start_time desc')
      @student_records = ""
      if @test_results.empty?
        flash[:notice] = "No test results."
      else
        flash[:notice] = nil
#        @Banner_sessions = []
        for test_result in @test_results
          test_record = ""
          student=Student.find_by_id(test_result.student_id)
          test = TestTemplate.find(test_result.template_version_id)
          test_record << student.last_name+","
          test_record << student.first_name+","
  #        test_record.gsub!(/'/,"\\\\'")
          test_record << student.birth_date.strftime("%m%d%y")+","
          test_record << student.student_number+","
          test_record << test.code+","+test_result.raw_score.to_i.to_s+","
          test_record << test_result.start_time.strftime("%Y%m%d")+","
          test_record << student.student_number
          @student_records << test_record+"\n"
#          @Banner_sessions << test_session.id
        end
      end
   end
  end

  def get_outstanding_records
      @test_sessions = TestSession.find(:all, :conditions => ["status = 'finished' and final_test is NOT NULL and processed = '1000-01-01 00:00:00'"])
      @student_records = ""
      if @test_sessions.empty?
        flash[:notice] = "No outstanding sessions found."
      else
        flash[:notice] = nil
        for test_session in @test_sessions
          test_record = ""
          student=Student.find_by_id(test_session.student_id)
          if not test_session.final_test?
            test = TestTemplate.find(test_session.final_test)
            test_record << student.last_name+","
            test_record << student.first_name+","
    #        test_record.gsub!(/'/,"\\\\'")
            test_record << student.birth_date.strftime("%m%d%y")+","
            test_record << student.student_number+","
            test_record << test.code+","+test_session.final_score.to_i.to_s+","
            test_record << test_session.start_time.strftime("%Y%m%d")+","
            test_record << student.student_number
            @student_records << test_record+"\n"
          end
        end
      end
   end
   
   #      Kernel.system("scp",file_name,"mathplac@daedalus.cocc.edu:"+destination_file)
   #      for session_id in @Banner_sessions
   #        s = TestSession.find_by_id(session_id)
   #        s.update_attribute(:processed,current_time)
   #      end
   #     flash[:notice] = 'Test results sent to Banner.'
   #    end
   

  def send_to_Banner
    @start_time = params["start_time"]
    @end_time = params["end_time"]
    @next_day = params["next_day"]
    @dates = params["dates"]
    @test_results = TestResult.find(:all, :conditions => ["status = 'finished' and start_time >= ? and start_time < ?",@start_time,@next_day], :order => 'student_id,start_time desc')
    @student_records = ""
    for test_result in @test_results
      test_record = ""
      student=Student.find_by_id(test_result.student_id)
      test = TestTemplate.find(test_result.template_version_id)
      test_record << student.last_name+","
      test_record << student.first_name+","
#        test_record.gsub!(/'/,"\\\\'")
      test_record << student.birth_date.strftime("%m%d%y")+","
      test_record << student.student_number+","
      test_record << test.code+","+test_result.raw_score.to_i.to_s+","
      test_record << test_result.start_time.strftime("%Y%m%d")+","
      test_record << student.student_number
      @student_records << test_record+"\n"
		end
    destination_file = "placementscores.csv"
#      destination_file = "placementscores.csv"+current_time.strftime("%Y%m%d.%H%M%S")
#      file_name = "/Library/WebServer/aux_files/"+destination_file
    file_name = "/home/deploy/"+destination_file
#      file_name = "/users/bill/"+destination_file
    #write file, set processed field of these sessions and offer to send them to Banner
    File.open(file_name, 'w') {|f| f.write(@student_records) }
  end

  def get_session_results_by_date
    flash[:notice] = nil
    if request.post?
      the_date = Time.local(params["the_date"]["year"],params["the_date"]["month"],params["the_date"]["day"])
      next_day = the_date.tomorrow
      @dates = "#{the_date.strftime('%m/%d/%Y')} to #{next_day.strftime('%m/%d/%Y')}."
      @test_sessions = TestSession.find(:all, :conditions => ["status = 'finished' and final_test is not null and start_time >= ? and start_time < ?",the_date,next_day])
      if @test_sessions.length == 0
        flash[:notice] = "No sessions for #{the_date.strftime('%m/%d/%Y')}."
      else
        @student_records = ""
  		  @Banner_sessions = []
  		  for test_session in @test_sessions
    			test_record = ""
    			student=Student.find_by_id(test_session.student_id)
      		if not test_session.final_test.blank?
      			test = TestTemplate.find(test_session.final_test)
      			test_record << student.last_name+","
      			test_record << student.first_name+","
      	#        test_record.gsub!(/'/,"\\\\'")
      			test_record << student.birth_date.strftime("%m%d%y")+","
      			test_record << student.student_number+","
      			test_record << test.code+","+test_session.final_score.to_i.to_s+","
      			test_record << test_session.start_time.strftime("%Y%m%d")+","
      			test_record << student.student_number
      			@student_records << test_record+"\n"
      			@Banner_sessions << test_session.id
    			end
  			end
      	if @Banner_sessions.length == 0
      			flash[:notice] = "No outstanding sessions found."
        end
    	end
      render :action => 'get_Banner_results_by_date'
    end
  end

  def TestResultsController.get_current_results
    the_date = Date.today
    @test_results = TestResult.find(:all, :conditions => ["status = 'finished' and start_time >= ?",the_date], :order => 'student_id')
    @student_records = ""
    for test_result in @test_results
      test_record = ""
      student=Student.find_by_id(test_result.student_id)
      test = TestTemplate.find(test_result.template_version_id)
      test_record << student.last_name+","
      test_record << student.first_name+","
#        test_record.gsub!(/'/,"\\\\'")
      test_record << student.birth_date.strftime("%m%d%y")+","
      test_record << student.student_number+","
      test_record << test.code+","+test_result.raw_score.to_i.to_s+","
      test_record << test_result.start_time.strftime("%Y%m%d")+","
      test_record << student.student_number
      @student_records << test_record+"\n"
		end
    destination_file = "placementscores.csv"
#      destination_file = "placementscores.csv"+current_time.strftime("%Y%m%d.%H%M%S")
#      file_name = "/Library/WebServer/aux_files/"+destination_file
    file_name = "/home/deploy/"+destination_file
#      file_name = "/users/bill/"+destination_file
    #write file, set processed field of these sessions and offer to send them to Banner
    File.open(file_name, 'w') {|f| f.write(@student_records) }
  end

  def get_test
    if request.post?
      current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      @student = Student.find_by_student_number(params[:student_number])
      if @student
        test_result = TestResult.find(:all, :conditions => ["status = ? and student_id = ? and start_time >= ?",'authorized',@student.id,current_time])
        if test_result.length == 0
          flash[:notice] = "No tests are currently authorized for student id #{params[:student_number]}."
        else
          redirect_to(:controller => 'test_session', :action => 'show_test', :student => params[:student_number], :test_results => test_result[0].id)
        end
      else
        flash[:notice] = "No student found with student id #{params[:student_number]}."
      end
    end
  end

  def score
    require 'open-uri'
    @test_results = TestResult.find(params[:test_results])
    @student = Student.find(@test_results.student_id)
    @test_template_id = TemplateVersion.find(@test_results.template_version_id).test_template_id
    if @test_results.status == 'finished'
#      flash[:notice] = "This test has already been scored."
      already_scored = true
    else
      already_scored = false
      TestSessionController.decrement_histogram(@test_template_id,@test_results.id,@test_results.score)
      AnswerRecord.destroy_all("test_result_id = #{@test_results.id}")
    end
    @test_results.status = 'finished'
    answers = @test_results.answers.split("<*>")
    @problem_list = @test_results.test_items.split("<*>")
    n = @problem_list.length
    section_names = []
    section = ""
    choices = []
    l = "A"
    26.times do 
    	 choices << l
       l = l.succ
    end
    i = 0
    score = 0
    @user_answers = []
    @key = []
    @missed_questions = []
		answertonumber = ["A" => 1, "B" => 2, "C" => 3, "D" => 4, "E" => 5];
		numbertoanswer = ["","A","B","C","D","E"];
    answer_records = []
    answer_records_valid = true
    @problem_list.each do |p|
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
        userchoice = keystring.index("1")
        key_answer = choices[keystring.index("1")]
        @key << key_answer
        temp_answer = answers[i-1].split(" ")
        temp_answer.delete_at(0)
        user_answer = temp_answer.to_s
        @user_answers << user_answer
        if user_answer == key_answer
          score += 1
        else
          @missed_questions << i.to_s + "<*>" + user_answer + "<*>" + key_answer +"<*>" + p
        end
        j = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".index(user_answer)
        if user_answer == ""
          decoded_answer = "N"
        else
          decoded_answer = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[keystring[j,1].to_i-1,1]
        end
      elsif code == "/f"
        i += 1
        number_choices = 0
        temp_answer = answers[i-1].split(" ")
        temp_answer.delete_at(0)
        user_answer = temp_answer.to_s
        parray = p.split("?")[1].split("&")
        encoded_problem = parray[0].split("=")[1]
        problem = URI.decode(encoded_problem)
        keylines = []
        open("http://math.lanecc.edu/getproblemanswers?problem=#{encoded_problem}&seed=#{parray[3].split("=")[1]}&useranswer=#{user_answer}") do |f|
          keylines << f.readlines
        end
        keystring = keylines[0].to_s
        keyarray = keystring.split(";<br>")
        key_answer = keyarray[0]
        @key << key_answer
        @user_answers << user_answer
        j = 0
        decoded_answer = "N"
        keylines.to_s.split("<br>\n").each do |k|
          if k.to_s.split(";<br>")[1].to_i == 1
            decoded_answer = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[j,1]
          end
          j += 1
        end
        if keyarray[1].to_i == 1
          score += 1
        else
          @missed_questions << i.to_s + "<*>" + user_answer + "<*>" + key_answer +"<*>" + p          
        end
        @keylines = keylines
      elsif code == "/s"
        section_names.push(section)
        section = p.split("/")[0]
        next
      elsif code == "/e" # end of section
        section = section_names.pop
        next
      else
          next
      end
      answer_record = AnswerRecord.new(:problem => problem, 
                                      :section => section, 
                                      :decoded_answer => decoded_answer, 
                                      :start_time => @test_results.start_time,
                                      :test_result => @test_results,
                                      :template_version_id => @test_results.template_version_id )
      answer_records << answer_record
      if not answer_record.valid?
        answer_records_valid = false
      end
    end
    if answer_records_valid and not already_scored
      answer_records.each {|a| a.save}
    elsif not already_scored
      flash[:notice] = "Unable to save answer records for data analysis as not all were valid."
    end
    @test_results.raw_score = score
    @score = (10000*score/1.0/i).round/100.0
    @test_results.score = @score
    if not already_scored
      @test_results.save
      @answer_records = answer_records
      TestSessionController.increment_histogram(@test_template_id,@score,@answer_records)
    end
  end
end
