class RecommendationController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @recommendation_pages, @recommendations = paginate :recommendations, :per_page => 20
  end

  def show
    @recommendation = Recommendation.find(params[:id])
  end

  def new
    @recommendation = Recommendation.new
  end

  def create
    @recommendation = Recommendation.new(params[:recommendation])
    if @recommendation.save
      flash[:notice] = 'Recommendation was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @recommendation = Recommendation.find(params[:id])
  end

  def update
    @recommendation = Recommendation.find(params[:id])
    if @recommendation.update_attributes(params[:recommendation])
      flash[:notice] = 'Recommendation was successfully updated.'
      redirect_to :action => 'show', :id => @recommendation
    else
      render :action => 'edit'
    end
  end

  def destroy
    Recommendation.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
  def init_recommendation_table
    sessions = TestSession.find(:all, :conditions => ["status = ?","finished"])
    for s in sessions
      test_list = TestResult.find(:all, :conditions => ["test_session_id = ?", s.id])
      h = Hash.new("empty")
      for t in test_list
        test_id = TemplateVersion.find(t.template_version_id)
        h[TestTemplate.find(test_id).name] = t.raw_score.to_s
      end
      test_vector = StudentsController.get_test_vector(h).to_s
      r = Recommendation.find(:first, :conditions => ["key_vector = ?", test_vector])
      if r.blank?
        r = Recommendation.new
        r.key_vector = test_vector
        r.rec = TestSessionController.get_recommendation(s.id)
        r.tally = 0
        if not r.rec.blank?
          r.save
        end
      end
    end
    redirect_to :action => 'list'
  end

  def tally_recommendation_table
    students = Student.find(:all)
    for student in students
      sessions = TestSession.find(:all, :conditions => ["status = ? and student_id = ?","finished",student.id], :order => 'start_time desc')
      if not sessions.empty?
        student.last_date = sessions[0].start_time
        vector_list = []
        for s in sessions
          test_list = TestResult.find(:all, :conditions => ["test_session_id = ? and status = ?", s.id,"finished"])
          h = Hash.new("empty")
          for t in test_list
            test_id = TemplateVersion.find(t.template_version_id)
            h[TestTemplate.find(test_id).name] = t.raw_score.to_s
          end
          test_vector = StudentsController.get_test_vector(h).to_s
          r = Recommendation.find(:first, :conditions => ["key_vector = ?", test_vector])
          if r.blank?
            r = Recommendation.new
            r.key_vector = test_vector
            r.rec = TestSessionController.get_recommendation(s.id)
            if r.rec != "Sequence has been deleted."
              r.tally = 0
              if not r.rec.blank?
                r.save
              end
            end
          end
          vector_list << [test_vector,r.rec]
        end
        vector_list.sort_by {|a| [a[0]]}
        vector_list.reverse!
        if not vector_list.empty? and vector_list[0][0] != "                    " and vector_list[0][1] != "Sequence has been deleted."
          v = Recommendation.find(:first, :conditions => ["key_vector = ?", vector_list[0][0]])
          v.tally += 1
          v.save
          student.test_vector = vector_list[0][0]
          student.save
        end
      end
    end
    redirect_to :action => 'list'
  end

end
