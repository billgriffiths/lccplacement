class TestTemplatesController < ApplicationController

  layout "admin"
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def save
    @test_template = TestTemplate.new(params[:test_template])
    if @test_template.save
      redirect_to(:action => 'show', :id => @test_template)
    else
      render(:action => :upload)
    end
  end

  def upload

  end
  
  def upload_test
    @test_template = TestTemplate.new(params[:test_template])
    redirect_to(:action => 'list')
  end

  def list
    @test_templates = TestTemplate.find(:all, :conditions => ["status = ?",'active'], :order => 'code')
#    @test_template_pages, @test_templates = paginate :test_templates, :per_page => 10
  end

  def show
    @test_template = TestTemplate.find(params[:id])
  end

  def new
    @test_template = TestTemplate.new
  end

  def create
    @test_template = TestTemplate.new(params[:test_template])
    if @test_template.save
      flash[:notice] = 'TestTemplate was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @test_template = TestTemplate.find(params[:id])
  end

  def update
    @test_template = TestTemplate.find(params[:id])
    version = TemplateVersion.find(@test_template.template_version_id)
    version.test_name = params[:test_template][:name]
#    rexp = Regexp.new(/(<key>Test<\/key>[\\r\\t]*<dict>[\\r\\t]*<key>name<\/key>[\\r\\t]*<string>)?[^<]*<\/string>/)
#    version.template.sub!(rexp,'\1'+params[:test_template][:name]+'</string>')
    if (version.save)      
      if @test_template.update_attributes(params[:test_template])      
          flash[:notice] = 'TestTemplate was successfully updated.'
          redirect_to :action => 'list', :id => @test_template
      else
        render :action => 'edit'
      end
    else
      flash[:notice] = 'Failed to update version for this test.'
    end
  end

  def destroy
    TestTemplate.find(params[:id]).update_attribute(:status,'inactive')
    redirect_to :action => 'list'
  end
end
