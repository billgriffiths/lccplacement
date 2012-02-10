class CutoffScoresController < ApplicationController

  layout "admin"
 
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list_sequences

  end

  def list
    @cutoff_scores = CutoffScore.find(:all).sort {|a,b| a.description <=> b.description  }
#    @cutoff_score_pages, @cutoff_scores = paginate :cutoff_scores, :per_page => 20
  end

  def show_sequence
    @sequence = TestSequence.find(params[:id])
    @cutoff_scores = CutoffScore.find(:all, :conditions => ["test_sequence_id = ?", @sequence.id], :order => 'seq_position')
    if @sequence.start_test_id.blank?
      @default_test_name = "none"
    else
      default_cutoff_score = CutoffScore.find(@sequence.start_test_id) # start_test_is a cutoff_score
      if default_cutoff_score.test_template_id.blank? # indicates a subsequence instead of a test
        @default_test_name = TestSequence.find(default_cutoff_score.subsequence_id).name + " sequence"
      else
        @default_test_name = TestTemplate.find(default_cutoff_score.test_template_id).name
      end
    end
  end

  def show
    @cutoff_score = CutoffScore.find(params[:id])
  end

  def new_sequence_test
    @sequence = TestSequence.find(params[:id])
    @cutoff_score = CutoffScore.new
    render :action => 'new'
  end

  def new
    @cutoff_score = CutoffScore.new
  end

  def create
    params[:cutoff_score]["test_sequence_id"] = params["test_sequence_id"]
    params[:cutoff_score][:seq_position] = params[:cutoff_score][:seq_position].to_i * 10 - 5
    @cutoff_score = CutoffScore.new(params[:cutoff_score])
    test_sequence = TestSequence.find_by_id(@cutoff_score.test_sequence_id)
    if @cutoff_score.save
      if test_sequence.start_test_id.blank?
        if @cutoff_score.test_template_id.blank?
          test_sequence.start_test_id = @cutoff_score.subsequence_id
        else
          test_sequence.start_test_id = @cutoff_score.test_template_id
        end
        test_sequence.save
      end
      flash[:notice] = 'Sequence test was successfully created.'
      redirect_to :action => 'show_sequence', :id => @cutoff_score.test_sequence_id
    else
      @sequence = TestSequence.find(params[:test_sequence_id])
      render :action => 'new'
    end
  end

  def edit
    @cutoff_score = CutoffScore.find(params[:id])
  end

  def edit_list
    @cutoff_scores = CutoffScore.find(:all, :order => "test_template_id, score")
  end

  def update
    @cutoff_score = CutoffScore.find(params[:id])
    position = params[:cutoff_score][:seq_position].to_i * 10
    if position > @cutoff_score.seq_position
      params[:cutoff_score][:seq_position] = position + 5
    else
      params[:cutoff_score][:seq_position] = position - 5
    end
    if @cutoff_score.update_attributes(params[:cutoff_score])
      flash[:notice] = 'Sequence test was successfully updated.'
      redirect_to :action => 'show_sequence', :id => @cutoff_score.test_sequence_id
    else
      render :action => 'edit'
    end
  end

  def destroy
    @sequence = CutoffScore.find(params[:id]).test_sequence_id
    CutoffScore.find(params[:id]).destroy
    redirect_to :action => 'show_sequence', :id => @sequence
  end
end
