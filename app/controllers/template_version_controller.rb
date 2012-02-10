class TemplateVersionController < ApplicationController

  layout "admin"
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
#    @template_version_pages, @template_versions = paginate :template_versions, :per_page => 10
    @template_versions = TemplateVersion.find(params[:all])
  end

  def show
    @template_version = TemplateVersion.find(params[:id])
  end

  def new
    @template_version = TemplateVersion.new
  end

  def create
    @template_version = TemplateVersion.new(params[:template_version])
    if @template_version.save
      flash[:notice] = 'TemplateVersion was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @template_version = TemplateVersion.find(params[:id])
  end

  def update
    @template_version = TemplateVersion.find(params[:id])
    if @template_version.update_attributes(params[:template_version])
      flash[:notice] = 'TemplateVersion was successfully updated.'
      redirect_to :action => 'show', :id => @template_version
    else
      render :action => 'edit'
    end
  end

  def destroy
    TemplateVersion.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
