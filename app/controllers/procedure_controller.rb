class ProcedureController < ApplicationController

  layout "admin"
 
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @procedure_pages, @procedures = paginate :procedures, :per_page => 10
  end

  def show
    @procedure = Procedure.find(params[:id])
  end

  def new
    @procedure = Procedure.new
  end

  def create
    @procedure = Procedure.new(params[:procedure])
    if @procedure.save
      flash[:notice] = 'Procedure was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @procedure = Procedure.find(params[:id])
  end

  def update
    @procedure = Procedure.find(params[:id])
#    params[:procedure][:text].gsub!(/\n/,"\<br\/\>")
    if @procedure.update_attributes(params[:procedure])
      flash[:notice] = 'Procedure was successfully updated.'
      redirect_to :action => 'show', :id => @procedure
    else
      render :action => 'edit'
    end
  end

  def destroy
    Procedure.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
