class TestSequenceController < ApplicationController

  layout "admin"
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @test_sequences = TestSequence.find(:all, :order => 'list_position')
#    @test_sequence_pages, @test_sequences = paginate :test_sequences, :order => 'name', :per_page => 10
  end

  def show
    @test_sequence = TestSequence.find(params[:id])
    redirect_to :controller => :cutoff_scores, :action => :show_sequence, :id => @test_sequence
  end

  def new
    @test_sequence = TestSequence.new
  end

  def create
    @test_sequence = TestSequence.new(params[:test_sequence])
    params[:test_sequence][:list_position] = params[:test_sequence][:list_position].to_i * 10 - 5
    if @test_sequence.save
      flash[:notice] = 'TestSequence was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @test_sequence = TestSequence.find(params[:id])
  end

  def update
    @test_sequence = TestSequence.find(params[:id])
    position = params[:test_sequence][:list_position].to_i * 10
    if position > @test_sequence.list_position
      params[:test_sequence][:list_position] = position + 5
    else
      params[:test_sequence][:list_position] = position - 5
    end
    if @test_sequence.update_attributes(params[:test_sequence])
      flash[:notice] = 'TestSequence was successfully updated.'
      redirect_to :action => 'list', :id => @test_sequence
    else
      render :action => 'edit'
    end
  end

  def destroy
    test_sequence = TestSequence.find(params[:id])
    test_sequence.cutoff_scores.destroy_all
    test_sequence.destroy
    redirect_to :action => 'list'
  end
end
