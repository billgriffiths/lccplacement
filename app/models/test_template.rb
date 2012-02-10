class TestTemplate < ActiveRecord::Base

  has_many    :template_versions
  has_many    :cutoff_scores

  validates_presence_of   :name, :status
#  validates_presence_of   :description

  validates_uniqueness_of :name
  
  def uploaded_test=(test_field)
    template = test_field.read
    doc = REXML::Document.new(template)
    testsection = doc.root.elements["dict"]
    self.name = testsection.elements[2].elements[2].text # test name
    template_version = TemplateVersion.new
    current_version = TestTemplate.find_by_name(self.name)
    if current_version.blank?
      version = 1
      template_version.version = version
      template_version.template = template
      if template_version.save
        self.template_version_id = template_version.id
        if self.save
          template_version.update_attribute(:test_template_id, self.id)
        else
          errors.add_to_base("failed to update test: #{self.name}")
        end
      else
        errors.add_to_base("failed to save template version: #{version}")
      end
    else
      version = TemplateVersion.find(:first, :conditions => ["test_template_id = ?",current_version.id], :order => "version desc").version + 1
      template_version.version = version
      template_version.template = template
      if template_version.save
        if current_version.update_attribute(:template_version_id, template_version.id)
          current_version.update_attribute(:status, 'active')
          template_version.update_attribute(:test_template_id, current_version.id)
        else
          errors.add_to_base("failed to update test: #{self.name}")
        end
      else
        errors.add_to_base("failed to save template version: #{version}")
      end
    end
  end

  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')
  end
  
  def display_name
    return name+"-"+description
  end

end
