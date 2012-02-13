class TestSessionController < ApplicationController
  
  before_filter :authorize_student_access, :except => [:student_login2, :staff_login, :show_recommendation, :show_find_next_test_in_sequence, :show_get_next_test, :show_session_results]
  
  def TestSessionController.section_problem_list(section)
    problem_list = []
    name = section.elements[2].elements[2].text
    instructions = section.elements[2].elements[4].text
    problem_list << name + "/s"
    if instructions.blank?
      problem_list << "/i"
    else
      problem_list << instructions + "/i"
    end
    randomize = section.elements[2].elements[8].to_s
    number_questions = section.elements[2].elements[10].text.to_i
    if randomize == "<true/>"
      entriesArray = shuffle(section.elements["array"].elements.to_a)
    else
      entriesArray = section.elements["array"].elements
    end
    i = 0
    number_questions.times do
      e = entriesArray[i]
      key = e.elements[1]
      if key.text == "Section"
        section_list = section_problem_list(e)
        section_list.each { |p| problem_list << p }
        problem_list << "/e" # end of section
      else
        name = e.elements[4].text
        multiple_choice = e.elements[6].to_s
        if multiple_choice == "<true/>"
          multiple_choice = "m"
        else
          multiple_choice = "f"
        end
        ext = name.split(".").last
        if ext == "5jpg"
          dir = "problems/5multchoiceimages"
          name.chomp!("."+ext)
          keystring = shuffle([1,2,3,4,5]).to_s
        elsif ext == "pedr"
          dir = "problems/PEmultchoiceimages"
          name.chomp!("."+ext)
          keystring = shuffle([1,2,3,4]).join(",")
        elsif ext == "pedx"
          dir = "problems/PEXmultchoiceimages"
          name.chomp!("."+ext)
          keyarray = []
          choices = e.elements[8].text.split(",")
          num_choices = choices[0].to_i
          if choices[1] == "none"
            1.upto(num_choices-1) {|t| keyarray << t}
            keystring = (shuffle(keyarray) << num_choices).join(",")
          else
            1.upto(num_choices) {|t| keyarray << t}
            keystring = shuffle(keyarray).join(",")
          end
        else
          dir = "problems/MRC"
          keystring = shuffle([1,2,3,4]).join(",")
        end
        problem = "#{dir}/#{name}/#{keystring}.jpg/#{multiple_choice}"
        problem_list << problem
        if i == entriesArray.length-1
          i = 0
          if randomize == "<true/>"
            entriesArray = shuffle(section.elements["array"].elements.to_a)
          else
            entriesArray = section.elements["array"].elements
          end
        else
          i += 1
        end
      end
    end
    return problem_list
  end

  def TestSessionController.shuffle(theArray)
    n = theArray.length
    for i in 0..n-2
      j = rand(n-i) # 0<=j<=n-i-1
      t = theArray[j] #swap the jth elt with the n-i-1th elt
      theArray[j] = theArray[n-i-1]
      theArray[n-i-1] = t
    end
    return theArray
  end

  def TestSessionController.generate_test_form(test_template)
    require "rexml/document"
    srand Time.now.to_i
    problem_list = []
    doc = REXML::Document.new(test_template)
    testsection = doc.root.elements["dict"]
    problem_list <<  testsection.elements[2].elements[2].text # test name
    number_questions = testsection.elements[2].elements[10].text
#    @answers.items = Array.new(number_questions.to_i) {|i| i}
    problem_list << testsection.elements[2].elements[4].text # test instructions
    randomize = testsection.elements[2].elements[8].to_s 
#    @numberQuestions = number_questions
    problem_list << number_questions
    if randomize == "<true/>"
      entriesArray = shuffle(testsection.elements["array"].elements.to_a)
    else
      entriesArray = testsection.elements["array"].elements
    end
    entriesArray.each do |e|
      key = e.elements[1]
      if key.text == "Section"
        section_list = section_problem_list(e)
        section_list.each { |p| problem_list << p }
        problem_list << "/e" # end of section
      else
        name = e.elements[4].text
        multiple_choice = e.elements[6].to_s
        if multiple_choice == "<true/>"
          multiple_choice = "m"
          ext = name.split(".").last
          if ext == "5jpg"
            dir = "problems/5multchoiceimages"
            name.chomp!("."+ext)
            keystring = shuffle([1,2,3,4,5]).to_s
          elsif ext == "pedr"
            dir = "problems/PEmultchoiceimages"
            name.chomp!("."+ext)
            keystring = shuffle([1,2,3,4]).join(",")
          elsif ext == "pedx"
            dir = "problems/PEXmultchoiceimages"
            name.chomp!("."+ext)
            keyarray = []
            choices = e.elements[8].text.split(",")
            num_choices = choices[0].to_i
            if choices[1] == "none"
              1.upto(num_choices-1) {|t| keyarray << t}
              keystring = (shuffle(keyarray) << num_choices).join(",")
            else
              1.upto(num_choices) {|t| keyarray << t}
              keystring = shuffle(keyarray).join(",")
            end
          else
            dir = "problems/MRC"
            keystring = shuffle([1,2,3,4]).join(",")
          end
          problem = "#{dir}/#{name}/#{keystring}.jpg/#{multiple_choice}"
        else
          multiple_choice = "f"
          name = URI.encode(name)
          problem = "getproblem.php?name=#{name}&key=5876&number=1&seed=2011919915&n=3&multipleChoice=0/#{multiple_choice}"
        end
        problem_list << problem
      end
    end
    return problem_list
  end
  
  def get_start_test
    test_session = TestSession.find(session[:test_session_id])
    @test_sequence = TestSequence.find(test_session.test_sequence_id)
    if test_session.start_test_id.blank? # a starting cutoff score has not been set.
      @cutoff_score = CutoffScore.find(:first,:conditions => ["test_sequence_id = ? and seq_position = 10",@test_sequence.id])
      test_session.start_test_id = @cutoff_score.id
      test_session.save
      redirect_to :action => 'get_start_test'
    else
      @cutoff_score = CutoffScore.find(test_session.start_test_id)
      if not @cutoff_score.test_template_id.blank? # blank indicates a subseuence instead of a test
        test_session.status = "started"
        test_session.save
#        @test_name = TestTemplate.find(cutoff_score.test_template).name
        redirect_to :action => :get_test, :cutoff_score => @cutoff_score
      elsif not cutoff_score.subsequence_id.blank?
        subsequence = TestSequence.find(cutoff_score.subsequence_id)
        current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        sub_session = TestSession.new
        sub_session["status"] = "started"
        sub_session["start_time"] = current_time
        sub_session.student_id = session[:student_id]
        sub_session.test_sequence_id = cutoff_score.subsequence_id
        sub_session.parent_session = test_session.id
        sub_session.processed = '1000-01-01 00:00:00'
        sub_session.location = session[:location]
        if subsequence.start_test_id.blank?
          sub_cutoff_score = CutoffScore.find(:first,:conditions => ["test_sequence_id = ? and seq_position = 10",cutoff_score.subsequence_id])
          sub_session.start_test_id = sub_cutoff_score.id
        else
          sub_session.start_test_id = subsequence.start_test_id
        end
        sub_session.save
        session[:test_session_id] = sub_session.id
        redirect_to :action => 'get_start_test'
      else
        flash[:notice] = "Error: the test id field and subsequence field is empty."
      end
    end
  end
  
  def get_sequence
    @test_session = TestSession.find(session[:test_session_id])
    @test_session.test_sequence_id = TestSequence.find(params[:seq]).id
    @test_session.save
    redirect_to :action => 'get_start_test'
  end

  def get_test
     current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
     @student = Student.find_by_id(session[:student_id])
     @cutoff_score = CutoffScore.find(params[:cutoff_score])
     @test_template = TestTemplate.find_by_id(@cutoff_score.test_template)
     test_result = TestResult.find(:first, :conditions => ["test_session_id = ? and template_version_id = ?",session[:test_session_id],@test_template.template_version_id])
     if test_result.blank?
        test_result = TestResult.new
        test_result.status = 'authorized'
        test_result.student_id = @student.id
        test_result.template_version_id = @test_template.template_version_id
        test_result.test_session_id = session[:test_session_id]
        test_result.start_time = current_time
        test_result.cutoff_score_id = @cutoff_score.id
        if test_result.save
          @student.add_test_result(test_result)
          @student.save
          redirect_to(:controller => 'test_session', :action => 'show_test', :test_results => test_result.id)
        else
          flash[:notice] = "Unable to create #{@test_template.description} record for student with id #{params[:student_number]}."
          render :controller => 'test_session', :action => 'student_login2' and return
        end
     elsif test_result.status == 'finished'
       flash[:notice] = "#{@test_template.description} has already been completed."
       @test_session = TestSession.find(session[:test_session_id])
       @test_sequence = TestSequence.find(@test_session.test_sequence_id)
       @cutoff_score = CutoffScore.find(test_result.cutoff_score_id)
       @score = test_result.score
       find_next_test_in_sequence
     else
       test_result.update_attribute(:status,"authorized")
       redirect_to(:controller => 'test_session', :action => 'show_test', :test_results => test_result.id)
     end
  end
  
  def get_next_test 
    @test_session = TestSession.find(session[:test_session_id])
    @test_sequence = TestSequence.find(@test_session.test_sequence_id)
    @cutoff_score = CutoffScore.find(params[:cutoff_score]) # cutoff_score is the one for the next test
    if not @cutoff_score.test_template_id.blank?
      next_test = TestTemplate.find(@cutoff_score.test_template_id)
      next_test_result = TestResult.find(:first, :conditions => ["test_session_id = ? and template_version_id = ?",@test_session.id,next_test.template_version_id])
      if next_test_result.blank? || next_test_result.status != 'finished'
        redirect_to :action => :get_test, :cutoff_score => @cutoff_score
      else # next test has already been completed so move on to the next
        @score = next_test_result.score
        find_next_test_in_sequence
      end
    else #next is a sequence
      next_seq_id = @cutoff_score.subsequence_id
      next_test_session = TestSession.find(:first, :conditions => ["parent_session = ? and test_sequence_id = ?",@test_session.id,next_seq_id])
      if next_test_session.blank? || next_test_session.status != 'finished'
        current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        sub_session = TestSession.new
        sub_session["status"] = "started"
        sub_session["start_time"] = current_time
        sub_session.student_id = session[:student_id]
        sub_session.test_sequence_id = next_seq_id
        sub_sequence = TestSequence.find(next_seq_id)
        sub_session.parent_session = @test_session.id
        sub_session.location = session[:location]
        sub_session.start_test_id = sub_sequence.start_test_id
        sub_session.processed = '1000-01-01 00:00:00'
        sub_cutoff_score = CutoffScore.find(sub_sequence.start_test_id)
        sub_session.save
        session[:test_session_id] = sub_session.id
        redirect_to :action => :get_next_test, :cutoff_score => sub_cutoff_score
      else # this shouldn't happen. subsequence has already been completed so we shouldn't be asked for the next test
        # since when a sub sequence is completed in a decision tree it should end there
        flash[:notice] = "Error: subsequence has been completed but the decision tree has not terminated."
        redirect_to :action => :session_results
      end
    end
  end

  def individual_tests
  end
  
  def get_individual_test
    @test_session = TestSession.find(session[:test_session_id])
    @test_session.test_sequence_id = params[:seq]
    test = TestTemplate.find_by_name(params[:test])
    @test_session.start_test_id = test.id
    @test_session.save
    redirect_to :action => 'get_start_test' 
  end
    
  def show_test
    if @answers.nil?
      @answers = Answers.new
    end
    @test_results = TestResult.find(params[:test_results])
    if @test_results.status == 'finished'
      flash[:notice] = "This test has already been completed and scored."
    end
    @test_version = TemplateVersion.find(@test_results.template_version_id)
    @test_background_color = @test_version.test_template.color
    if @test_results.test_items.nil?
      @test_list = TestSessionController.generate_test_form(@test_version.template)
      @test_results.test_items =  @test_list.join("<*>")
      @test_results.status = 'started'
    else
      @test_list = @test_results.test_items.split("<*>")
    end
    @n = @test_list[2].to_i
    if @test_results.answers.nil?
      @answers.items = Array.new(@n) {|i| (i+1).to_s+"."}
      @test_results.answers = @answers.items.join("<*>")
    else
      @answers.items = @test_results.answers.split("<*>")
    end
    @test_results.save
    session[:test_results] = @test_results
  end
  
  def TestSessionController.decrement_histogram(test_template_id,test_results_id,score)
    require 'YAML'
    test_version = TemplateVersion.find(test_template_id) # most recent version
    answer_records = AnswerRecord.find(:all, :conditions => ["test_result_id = ?","test_results_id"])
    histogram = YAML.load(test_version.histogram)
    nScores = test_version.number_scores
    if not score.blank?
      nScores -= 1
      percentile = ((score/10).floor*10).to_i
      if percentile == 100
        percentile = 90
      end
      histogram[percentile]["count"] -= 1
      answer_records.each do |a|
        if not histogram[percentile][a.section][a.problem].blank?
          histogram[percentile][a.section]["total"] -= 1
          histogram[percentile][a.section]["correct"] -= 1 if a.decoded_answer == "A"
          histogram[percentile][a.section][a.problem]["total"] -= 1
          histogram[percentile][a.section][a.problem]["correct"] -= 1 if a.decoded_answer == "A"
        end
      end
      test_version.histogram = YAML.dump(histogram)
      test_version.number_scores = nScores
      test_version.save
    end
  end

  def TestSessionController.increment_histogram(test_template_id,score,answer_records)
    require 'YAML'
    test_version = TemplateVersion.find(test_template_id) # most recent version
    histogram = YAML.load(test_version.histogram)
    nScores = test_version.number_scores
    if not score.blank?
      nScores += 1
      percentile = ((score/10).floor*10).to_i
      if percentile == 100
        percentile = 90
      end
      histogram[percentile]["count"] += 1
      answer_records.each do |a|
        if not histogram[percentile][a.section][a.problem].blank?
          histogram[percentile][a.section]["total"] += 1
          histogram[percentile][a.section]["correct"] += 1 if a.decoded_answer == "A"
          histogram[percentile][a.section][a.problem]["total"] += 1
          histogram[percentile][a.section][a.problem]["correct"] += 1 if a.decoded_answer == "A"
        end
      end
      test_version.histogram = YAML.dump(histogram)
      test_version.number_scores = nScores
      test_version.save
    end
  end

  def score
    require 'open-uri'
    flash[:test_results] = []
    @test_results = TestResult.find(session[:test_results])
    @test_session = TestSession.find(session[:test_session_id])
    @student = Student.find(@test_results.student_id)
    @test_template_id = TemplateVersion.find(@test_results.template_version_id).test_template_id
    if @test_results.status == 'finished'
      flash[:notice] = "This test has already been scored."
      already_scored = true
#      would like to short circuit as follows except view results option uses this code to gnerate the item results
#      @score = @test_results.score
#      find_next_test_in_sequence # since we aren't going to show the results to the student can branch directly to next test
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
                                      :template_version_id => @test_results.template_version_id,
                                      :choices => number_choices )
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
    @test_sequence = TestSequence.find(@test_session.test_sequence_id)
    @cutoff_score = CutoffScore.find(@test_results.cutoff_score_id)
    find_next_test_in_sequence
  end
  
  def find_next_test_in_sequence
    @test_session = TestSession.find(session[:test_session_id])
    @student = Student.find(session[:student_id])
    if @score >= @cutoff_score.score
      if not @cutoff_score.pass_cutoff_score.blank?
        if CutoffScore.find(@cutoff_score.pass_cutoff_score).test_template_id ==  @cutoff_score.test_template_id
          @cutoff_score = CutoffScore.find(@cutoff_score.pass_cutoff_score)
          find_next_test_in_sequence
        else
          @cutoff_score = CutoffScore.find(@cutoff_score.pass_cutoff_score)
          redirect_to :action => :get_next_test, :cutoff_score => @cutoff_score
        end
      else
        @recommendation = @cutoff_score.recommendation
        redirect_to :action => :session_results, :recommendation => @recommendation, :final_cutoff_score => @cutoff_score
      end
    else
      if not @cutoff_score.fail_cutoff_score.blank?
        @cutoff_score = CutoffScore.find(@cutoff_score.fail_cutoff_score)
        redirect_to :action => :get_next_test, :cutoff_score => @cutoff_score
      else
        @recommendation = @cutoff_score.alternate_recommendation
        redirect_to :action => :session_results, :recommendation => @recommendation, :final_cutoff_score => @cutoff_score
      end
    end
  end
  
  def show_recommendation
    @test_session = TestSession.find(params[:test_session_id])
    @student = Student.find(@test_session.student_id)
    @test_results = TestResult.find(:all, :conditions => ["test_session_id = ?", @test_session.id ])
    @test_results.each do |r| 
      if @test_session.start_test_id == r.cutoff_score_id
        @test_result = r
      end
    end
    if not @test_result.blank?
      @test_sequence = TestSequence.find(:all, :conditions => ["id = ?", @test_session.test_sequence_id ])
      if not @test_sequence.empty?
        @test_sequence = TestSequence.find(@test_session.test_sequence_id)
        @cutoff_score = CutoffScore.find(@test_result.cutoff_score_id)
        @score = @test_result.score
        show_find_next_test_in_sequence
      else
        redirect_to :action => :show_session_results, :recommendation => "Test sequence has been deleted.", :student => @student, :test_session => @test_session.id
      end
    else
      redirect_to :action => :show_session_results, :recommendation => "No recommendation found", :student => @student, :test_session => @test_session.id
    end
  end

  def show_get_next_test 
    @test_results = TestResult.find(:all, :conditions => ["test_session_id = ?", @test_session ])
    @test_results.each do |r| 
      if @cutoff_score.id == r.cutoff_score_id
        @test_result = r
      end
    end
   if not @test_result.blank?
      @score = @test_result.score
      show_find_next_test_in_sequence
    else
      flash[:notice] = "No recommendation found."
    end
  end

  def show_find_next_test_in_sequence
    if @score >= @cutoff_score.score
      if not @cutoff_score.pass_cutoff_score.blank?
        if CutoffScore.find(@cutoff_score.pass_cutoff_score).test_template_id == @cutoff_score.test_template_id
          @cutoff_score = CutoffScore.find(@cutoff_score.pass_cutoff_score)
          show_find_next_test_in_sequence
        else
          @cutoff_score = CutoffScore.find(@cutoff_score.pass_cutoff_score)
          show_get_next_test
        end
      else
        @recommendation = @cutoff_score.recommendation
        redirect_to :action => :show_session_results, :recommendation => @recommendation, :student => @student, :test_session => @test_session.id
      end
    else
      if not @cutoff_score.fail_cutoff_score.blank?
        @cutoff_score = CutoffScore.find(@cutoff_score.fail_cutoff_score)
        show_get_next_test
      else
        @recommendation = @cutoff_score.alternate_recommendation
        redirect_to :action => :show_session_results, :recommendation => @recommendation, :student => @student, :test_session => @test_session.id
      end
    end
  end

  def show_session_results
    @recommendation = params[:recommendation]
    @student = Student.find(params[:student])
    @test_session = TestSession.find(params[:test_session])
    @test_date = @test_session.start_time
    @results_list = []
    TestSessionController.get_test_results(@test_session,@results_list)
    @results_list.sort! {|x,y| x.start_time <=> y.start_time}
  end
  
  def TestSessionController.get_recommendation test_session_id
    @test_session = TestSession.find(test_session_id)
    @test_results = TestResult.find(:all, :conditions => ["test_session_id = ? and status = ?", @test_session.id, "finished" ])
    @test_results.each do |r| 
      if @test_session.start_test_id == r.cutoff_score_id
        @test_result = r
      end
    end
    if not @test_result.blank?
      @test_sequence = TestSequence.find(:all, :conditions => ["id = ?", @test_session.test_sequence_id ])
      if not @test_sequence.empty?
        @cutoff_score = CutoffScore.find(:all, :conditions => ["id = ?",@test_result.cutoff_score_id])
        if @cutoff_score.empty?
          return "Sequence has been deleted."
        end
        @score = @test_result.score
        @cutoff_score = @cutoff_score[0]
        return TestSessionController.rec_from_next_test_in_sequence
      else
        return "Sequence has been deleted."
      end
    else
      return "No recommendation found."
    end
  end

  def TestSessionController.rec_from_next_test 
    @test_results = TestResult.find(:all, :conditions => ["test_session_id = ?", @test_session ])
    @test_results.each do |r| 
      if @cutoff_score.id == r.cutoff_score_id
        @test_result = r
      end
    end
   if not @test_result.blank?
      @score = @test_result.score
      return TestSessionController.rec_from_next_test_in_sequence
    else
      return "No recommendation found."
    end
  end

  def TestSessionController.rec_from_next_test_in_sequence
    if @score >= @cutoff_score.score
      if not @cutoff_score.pass_cutoff_score.blank?
        if CutoffScore.find(@cutoff_score.pass_cutoff_score).test_template_id == @cutoff_score.test_template_id
          @cutoff_score = CutoffScore.find(@cutoff_score.pass_cutoff_score)
          return TestSessionController.rec_from_next_test_in_sequence
        else
          @cutoff_score = CutoffScore.find(@cutoff_score.pass_cutoff_score)
          return TestSessionController.rec_from_next_test
        end
      else
        return @cutoff_score.recommendation
      end
    else
      if not @cutoff_score.fail_cutoff_score.blank?
        @cutoff_score = CutoffScore.find(@cutoff_score.fail_cutoff_score)
        return TestSessionController.rec_from_next_test
      else
        return @cutoff_score.alternate_recommendation
      end
    end
  end
  
  def update_answers
    if @answers.nil?
      @answers = Answers.new
    end
    answer = params[:answer]
    answerarray = answer.split(" ")
    i = answerarray[0].to_i
    @current_answer = answer
    @test_results = session[:test_results]
    @answers.items = @test_results.answers.split("<*>")
    if @test_results.status == 'finished'
      @current_answer = @answers.items[i-1]
    else
      @answers.items[i-1] = answer
      @test_results.answers = @answers.items.join("<*>")
      @test_results.save
    end
  end
  
  def get_subsession_results(parent)
    subsessions = TestSession.find(:all, :conditions => ["parent_session=?",parent])
    subsessions.each do |sub|
      subsession_test_results = TestResult.find(:all, :conditions => ["test_session_id = ?",sub.id])
      subsession_test_results.each do |s|
        @test_results << s
      end
      get_subsession_results(sub.id)
    end
  end

  def student_resume_test
    session[:user_id] = nil
    @student = Student.find(session[:student_id])
    if @student
      if session[:test_session_id].blank?
        redirect_to(:action => "create_session")
      else
        @test_results = TestResult.find(:all, :conditions => ["test_session_id = ?",session[:test_session_id]])
        get_subsession_results(session[:test_session_id])
        test_session = TestSession.find(session[:test_session_id])
        if test_session.parent_session != 0
          TestSessionController.get_test_results(test_session.parent_session,@test_results)
        end
        @test_results.sort! {|x,y| x.start_time <=> y.start_time}
      end
    else
      redirect_to( :action => "student_login2" )
    end
  end

  def resume
    redirect_to(:action => "staff_login")
  end

  def authorize_resume_test
    @test_result = TestResult.find(params[:id])
    @student = Student.find(session[:student_id])
    if request.post?
      @test_result.update_attribute(:status,"authorized")
      @test = TestTemplate.find(TemplateVersion.find(@test_result.template_version_id).test_template_id)
#      @test_name = @test.name
      test_session = TestSession.find(@test_result.test_session_id)
      test_session.status = "authorized"
      test_session.start_time = Time.now + params[:time_limit].to_i*60
      @cutoff_score = CutoffScore.find(@test_result.cutoff_score_id)
#      cutoff_score = CutoffScore.find(:first, :conditions =>["test_template_id = ? and test_sequence_id = ?",@test.id,test_session.test_sequence_id])
      test_session.start_test_id = @cutoff_score.id
      test_session.save
      session[:test_session_id] = test_session.id
      flash[:notice] = "#{@student.first_name} #{@student.last_name} was successfully authorized to resume #{@test.description}."
      render :action => 'student_intro'
    end
  end

  def staff_login
    if request.post?
      user = User.authenticate(params[:user_name], params[:password])
      if user
        session[:location] = user.location
        # will create test session if none active
        redirect_to(:action => "student_resume_test")
      else
        flash[:notice] = "Invalid user name or password"
      end
    end
  end

  def create_session
    @student = Student.find_by_id(session[:student_id])
  end

  def authorize_testing_session
    @student = Student.find(params[:student])
    if not params[:test_sequence_id].blank?
       TestSession.find(:all, :conditions => ["status != ? and student_id = ?",'finished',params[:student]]).each do |r|
          r.status = "terminated"
          r.save
       end
       @test_session = TestSession.new
       @test_session.status = 'authorized'
       @test_session.student_id = @student
       @test_session.start_time = Time.now + 15*60
       @test_session.test_sequence_id = params[:test_sequence_id]
       @test_session.parent_session = 0
       @test_session.processed = '1000-01-01 00:00:00'
       # get authorized cutoff_score for this session; this is the starting test or sequence
       @sequence = TestSequence.find(params[:test_sequence_id])
       if @sequence.name == 'Individual Tests'
         @test_session.start_test_id = nil
       else
         @test_session.start_test_id = TestSequence.find_by_id(params[:test_sequence_id]).start_test_id
       end
       @test_session.location = session[:location]
       if @test_session.save
         @student.add_test_session(@test_session)
         @student.save
         session[:test_session_id] = @test_session.id
#         flash[:notice] = "Test session was successfully authorized for #{@student.first_name} #{@student.last_name}."
          if @sequence.name == 'Individual Tests'
            redirect_to(:action => 'choose_individual_test')
          else
            redirect_to(:action => 'student_intro')
          end
       else
         flash[:notice] = "Unable to save test session for #{@student.first_name} #{@student.last_name}."
         render :action => 'create_session'
       end
     else
       flash[:notice] = "You must select a test sequence."
       render :action => 'create_session'
     end
  end
  
  def choose_individual_test
    @individual_sequence = TestSequence.find(:first, :conditions => ["name = ?", 'Individual Tests'])
    @cutoff_scores = CutoffScore.find(:all, :conditions => ["test_sequence_id = ?", @individual_sequence.id])
    @tests = []
    for c in @cutoff_scores
      @tests << TestTemplate.find_by_id(c.test_template_id)
    end
    @tests.sort! {|x,y| x.name <=> y.name}
  end

  def set_individual_test
    @test_session = TestSession.find_by_id(session[:test_session_id])
    @test_session.start_test_id = CutoffScore.find(:first,:conditions => ["test_sequence_id = ? and test_template_id = ?",@test_session.test_sequence_id,params[:test_id]]).id
    if not @test_session.save
      @student = Student.find_by_id(session[:student_id])
      flash[:notice] = "Unable to save test session for #{@student.first_name} #{@student.last_name}."
      render :action => 'create_session'
    else
      redirect_to(:action => 'student_intro')
    end
  end

  def student_login2
    session[:student_id] = nil
    session[:user_id] = nil
    @student = Student.new(params[:student])
    if request.post?
      flash[:notice] = nil
      if not (params['birth_date']['birth_date(1i)'].blank? || params['birth_date']['birth_date(2i)'].blank? || params['birth_date']['birth_date(3i)'].blank?)
        birth_date = Date.new(params['birth_date']['birth_date(1i)'].to_i,params['birth_date']['birth_date(2i)'].to_i,params['birth_date']['birth_date(3i)'].to_i)
      end
      @student.birth_date = birth_date
      current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      @old_Student = Student.find_by_student_number(params[:student][:student_number])
      if @old_Student.blank?
        if not @student.save
#          flash[:notice] = "Student data ( #{params[:student][:student_number]} #{params[:student][:first_name]}
            #{params[:student][:last_name]} #{params[:student][:phone]} #{birth_date}) is incomplete or invalid."
          render :controller => 'test_session', :action => 'student_login2' and return
        end
      elsif birth_date != @old_Student.birth_date || 
        params[:student][:first_name].upcase != @old_Student.first_name.upcase || 
        params[:student][:last_name].upcase != @old_Student.last_name.upcase # phone could be different
        if not birth_date.blank?
          flash[:notice] = "Student data ( #{params[:student][:student_number]} #{params[:student][:first_name]}
            #{params[:student][:last_name]} #{birth_date.strftime('%m/%d/%Y')}) is inconsistent with database records."
        else
          flash[:notice] = "Birth date cannot be blank."
        end
        render :controller => 'test_session', :action => 'student_login2' and return
      else
        @student = @old_Student
      end
      session[:student_id] = @student.id
      test_session = TestSession.find(:first, :conditions => ["status = 'authorized' and student_id = #{@student.id} and start_time >= '#{current_time}'"])
      if test_session.blank?
        redirect_to(:action => 'create_session') and return
      else
        session[:test_session_id] = test_session.id
        test_session["status"] = "started"
        test_session["start_time"] = current_time
        test_session.save
        redirect_to(:action => 'student_intro') and return
      end
    end
  end

  def student_login
    session[:student_id] = nil
    session[:user_id] = nil
    if request.post?
      current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      @student = Student.find_by_student_number(params[:student_number])
      if @student.blank?
        flash[:notice] = "No student with id #{params[:student_number]} was found."
      else
        test_session = TestSession.find(:first, :conditions => ["status = 'authorized' and student_id = #{@student.id} and start_time >= '#{current_time}'"])
        if test_session.blank?
          flash[:notice] = "Student with id #{params[:student_number]} is not currently authorized for testing."
        else
          session[:student_id] = @student.id
          session[:test_session_id] = test_session.id
          test_session["status"] = "started"
          test_session["start_time"] = current_time
          test_session.save
          redirect_to(:action => 'student_intro')
        end
      end
    end
  end

  def student_logout
    session[:student_id] = nil
    session[:test_session_id] = nil
    session[:test_results] = nil
    flash[:notice] = "logged out"
    redirect_to(:action  => "staff_login")
  end

  def student_intro
    test_session = TestSession.find(session[:test_session_id])
    @student_choice = (test_session.start_test_id.blank?) # blank indicates no sequence has been authorized.
    # branch on sequence name instead of start test since may want start test to be non null
    if not @student_choice # a sequence has been authorized.
      @cutoff_score = CutoffScore.find(test_session.start_test_id)
      test_session.status  = "started"
      test_session.save
      if not @cutoff_score.test_template_id.blank? # blank indicates a subseuence instead of a test
#        @test_name = TestTemplate.find(cutoff_score.test_template).name
      elsif not @cutoff_score.subsequence_id.blank?
        subsequence = TestSequence.find(@cutoff_score.subsequence_id)
        current_time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        sub_session = TestSession.new
        sub_session["status"] = "started"
        sub_session["start_time"] = current_time
        sub_session.student_id = session[:student_id]
        sub_session.test_sequence_id = @cutoff_score.subsequence_id
        sub_session.parent_session = test_session.id
        sub_ssession.processed = '1000-01-01 00:00:00'
        sub_session.location = session[:location]
        if subsequence.start_test_id.blank?
          sub_cutoff_score = CutoffScore.find(:first,:conditions => ["test_sequence_id = ? and seq_position = 10",@cutoff_score.subsequence_id])
          sub_session.start_test_id = sub_cutoff_score.id
        else
          sub_session.start_test_id = subsequence.start_test_id
        end
        sub_session.save
        session[:test_session_id] = sub_session.id
        redirect_to :action => 'student_intro'
      else
        flash[:notice] = "Error: the test id field and subsequence field is empty."
      end
    end
  end
  
  def pass_sequence(session_id)
    session = TestSession.find(session_id)
    sequence = TestSequence.find(session.test_sequence_id)
    cutoff_scores = CutoffScore.find(:all, :conditions => ["test_sequence_id = ?",sequence.id], :order => 'seq_position')
    c = cutoff_scores.last
    the_test_result = nil
    if not c.test_template_id.blank?
      test_versions = TemplateVersion.find(:all, :conditions => ["test_template_id = ?", c.test_template_id])
      test_versions.each do |v|
        test_result = TestResult.find(:first, :conditions => ["test_session_id = ? and template_version_id = ?", session_id, v])
        if not test_result.blank?
          the_test_result = test_result
        end
      end
      if the_test_result.blank?
        pass = false
      else
        pass = (the_test_result.score >= c.score)
      end
    else # we have a sequence
      subsession = TestSession.find(:first, :conditions => ["parent_session = ? and test_sequence_id = ?",session_id,c.subsequence_id])
      if not subsession.blank?
        pass = pass_sequence(subsession.id)
      else # error
        pass = false
      end
    end
    return pass
  end
  
  def TestSessionController.get_test_results(session_id,results_list)
    session = TestSession.find(session_id)
    if session.parent_session != 0
      get_test_results(session.parent_session,results_list)
    end
    TestResult.find(:all, :conditions => ["status = ? and test_session_id = ?", "finished", session_id]).each do |r|
      results_list << r
    end
  end
  
  def session_results
    session[:user_id] = nil
    @test_session = TestSession.find(session[:test_session_id])
    @student = Student.find(session[:student_id])
    @recommendation = params[:recommendation]
    final_cutoff = CutoffScore.find(params[:final_cutoff_score]) 
    if final_cutoff.score.blank? # it was a sequence
      @subsession = TestSession.find(:first, :conditions => ["parent_session = ?",@test_session.id])
      @test_session.update_attribute(:final_test,@subsession.final_test)
      @test_session.update_attribute(:final_score,@subsession.final_score)
    else
      test = TestTemplate.find(final_cutoff.test_template_id)
      test_result = TestResult.find(:first, :conditions => ["test_session_id = ? and template_version_id = ?",@test_session.id,test.template_version_id])
      @test_session.update_attribute(:final_test,final_cutoff.test_template_id)
      @test_session.update_attribute(:final_score,test_result.raw_score)
    end
    @test_session.update_attribute(:status,'finished')
    @results_list = []
    TestSessionController.get_test_results(@test_session.id,@results_list)
    @results_list.sort! {|x,y| x.start_time <=> y.start_time}
    h = Hash.new("empty")
    for t in @results_list
      test_id = TemplateVersion.find(t.template_version_id)
      h[TestTemplate.find(test_id).name] = t.raw_score.to_s
    end
    test_vector = StudentsController.get_test_vector(h).to_s
    r = Recommendation.find(:first, :conditions => ["key_vector = ?", test_vector])
    current_test_vector = @student.test_vector
    if current_test_vector.blank?
      @student.update_attribute(:test_vector,test_vector)     
    elsif test_vector >= current_test_vector     
      if r.blank?
        r = Recommendation.new
        r.key_vector = test_vector
        r.rec = TestSessionController.get_recommendation(@test_session.id)
        r.tally = 1
        if not r.rec.blank?
          r.save
        end
      else
        r.update_attribute(:tally,r.tally + 1)     
        r = Recommendation.find(:first, :conditions => ["key_vector = ?", current_test_vector])
        r.update_attribute(:tally,r.tally - 1)     
      end
      @student.update_attribute(:test_vector,test_vector)     
    end
    @student.update_attribute(:last_date,@test_session.start_time)     
    close_parent_sessions(@test_session)
  end
  
  def close_parent_sessions(test_session_id)
    test_session = TestSession.find(test_session_id)
    if test_session.parent_session !=0 # 0 indicates the primary session
      parent_session = TestSession.find(test_session.parent_session)
      parent_session.update_attribute(:status,'finished')
      close_parent_sessions(parent_session)
    end
  end
  
  def authorize_student_access
    unless Student.find_by_id(session[:student_id])
      session[:original_url] = request.request_uri
  #      flash[:notice] = "Please Log In"
      redirect_to(:action => "student_login2") and return false
    end
  end
end
