class TemplateVersion < ActiveRecord::Base
  
  belongs_to  :test_template
  has_many    :answer_records
  has_many    :test_results
  
  validates_presence_of   :version, :template
  
  def test_name=(name_text)
    rexp = Regexp.new(/(<key>Test<\/key>\s*<dict>\s*<key>name<\/key>\s*<string>)?[^<]*<\/string>/)
    self.template.sub!(rexp,'\1'+name_text+'</string>')
  end
  
end
