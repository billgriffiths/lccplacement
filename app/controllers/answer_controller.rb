class AnswerController < ApplicationController

  layout "admin"
  
  def analyze_answers
    
  end
  
  def analyze_problem
    @problem_name = params[:name]
    @problem = AnswerRecord.find(:first, "", :conditions => ["problem = ?", @problem_name])    
    if @problem.blank?
      flash[:notice] = "No problem chosen."
      redirect_to(:action => 'analyze_answers')
    else
      @ext = @problem_name.split(".").last
      if @ext == "pedr" or @ext == "jpg"
        @n = 4
      elsif @ext == "pedx"
        @n = @problem.choices.to_i
      elsif @ext == "5jpg"
        @n = 5
      else
        @n = 5
      end
      @frequency = {}
      l = "A"
      @n.times do
        @frequency[l] = 0
        l = l.succ
      end
      @frequency["N"] = 0
      @records = AnswerRecord.find(:all, "", :conditions => ["problem = ?", @problem_name])
      if @records.blank?
        # should never be blank since the problem was chosen from a list of existing problems
      elsif
        @records.each do |r|
          @frequency[r.decoded_answer] += 1
        end
      end
      if request.xhr?
        @ajax_call = true
        render :action => 'analyze_problem', :layout => false
      else
        @ajax_call = false
        render :action => 'analyze_problem'
      end 
    end
  end
  
  def analyze_test
#    require 'set'
    require 'YAML'
    @test = TestTemplate.find(params[:test])
    if @test.blank?
      flash[:notice] = "No test chosen."
      redirect_to(:action => 'analyze_answers')
    else
      @test_version = TemplateVersion.find(@test.template_version_id) # most recent version
      generate_test_section_list(@test_version.template)
      @test_sections = @test_section.keys
      @test_sections.sort!
      @test_sections.each { |s| @test_section[s].uniq! }
      if @test_version.histogram.blank?
        @histogram = {}
        10.times do |i|
          @histogram[i*10] = {}
          @histogram[i*10]["count"] = 0
          @test_sections.each do |s|
            @histogram[i*10][s] = {}
            @histogram[i*10][s]["total"] = 0
            @histogram[i*10][s]["correct"] = 0
            @test_section[s].each do |p|
              @histogram[i*10][s][p] = {}
              @histogram[i*10][s][p]["total"] = 0
              @histogram[i*10][s][p]["correct"] = 0
            end
          end
        end
        @nScores = 0
        @test_version.test_results.each do |r|
          if not r.score.blank? then
            @nScores += 1
            percentile = ((r.score/10).floor*10).to_i
            if percentile == 100
              percentile = 90
            end
            @histogram[percentile]["count"] += 1
            r.answer_records.each do |a|
              if not @histogram[percentile][a.section][a.problem].blank?
                @histogram[percentile][a.section]["total"] += 1
                @histogram[percentile][a.section]["correct"] += 1 if a.decoded_answer == "A"
                @histogram[percentile][a.section][a.problem]["total"] += 1
                @histogram[percentile][a.section][a.problem]["correct"] += 1 if a.decoded_answer == "A"
              end
            end
          end
        end
        @test_version.histogram = YAML.dump(@histogram)
        @test_version.number_scores = @nScores
        @test_version.save
      else
        @histogram = YAML.load(@test_version.histogram)
        @nScores = @test_version.number_scores
      end
      @histogramTotal = {}
      @test_sections.each do |s|
        @histogramTotal[s] = {}
        @test_section[s].each do |p|
          @histogramTotal[s][p] = {}
          @histogramTotal[s][p]["n_scores"] = 0
          10.times do |i|
            @histogramTotal[s][p]["n_scores"] += @histogram[i*10][s][p]["total"]
          end
        end
      end
    end
  end
  
  def section_problem_list(section)
    sname = section.elements[2].elements[2].text
    @section_names.push(@section)
    @section = sname
    @test_section[@section] = []
    entriesArray = section.elements["array"].elements
    entriesArray.each do |e|
      key = e.elements[1]
      if key.text == "Section"
        section_problem_list(e)
      else
        pname = e.elements[4].text
        ext = pname.split(".").last
        multiple_choice = e.elements[6].to_s
        if multiple_choice == "<true/>"
          if ext == "5jpg"
            num_choices = 5
          elsif ext == "pedr"
            num_choices = 4
          elsif ext == "pedx"
            choices = e.elements[8].text.split(",")
            num_choices = choices[0].to_i
          else
            pname += '.jpg'
            num_choices = 4
          end
        else
          num_choices = 0
        end
        @test_section[@section] << pname
        @nChoices[pname] = num_choices
      end
    end
     @section = @section_names.pop
  end

  def generate_test_section_list(test_template)
    require "rexml/document"
    @section_names = []
    @section = ""
    @test_section = {}
    @test_section[@section] = []
    @nChoices = {}
    doc = REXML::Document.new(test_template)
    testsection = doc.root.elements["dict"]
    entriesArray = testsection.elements["array"].elements
    entriesArray.each do |e|
      key = e.elements[1]
      if key.text == "Section"
        section_problem_list(e)
      else
        pname = e.elements[4].text
        @test_section[@section] << pname
        ext = pname.split(".").last
        multiple_choice = e.elements[6].to_s
        if multiple_choice == "<true/>"
          if ext == "5jpg"
            num_choices = 5
          elsif ext == "pedr"
            num_choices = 4
          elsif ext == "pedx"
            choices = e.elements[8].text.split(",")
            num_choices = choices[0].to_i
          else
            pname += '.jpg'
            num_choices = 4
          end
        else
          num_choices = 0
        end
        @test_section[@section] << pname
        @nChoices[pname] = num_choices
      end
    end
  end
    
end
