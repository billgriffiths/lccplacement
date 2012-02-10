class ColorPickerFormBuilder < ActionView::Helpers::FormBuilder
  
  def color_picker(method, options={})
    toret = "<div class=\"colorpicker\">" 
    available = { 1 => "#CCCCCC",
                  2 => "#CCFFFF",
                  3 => "#FFCCFF",
                  4 => "#CFFFCC",
                  5 => "#CFCFFF" 
                }

    available.each_pair do |key,opt|
      toret += "<div id=\"coloritem_#{key}\" class=\"coloritem " + (opt == options[:selected] ? "cpselected" : "") + "\" style=\"background: #{opt}\">" 
      toret += "<a href=\"#\" onClick=\"set_color_picker('coloritem_#{key}','#{opt}');return false;\"></a>" 
      toret += "</div>\n" 
    end
    toret += "<input type=\"hidden\" name=\"#{@object_name.to_s}[#{method.to_s}]\" value=\"#{options[:selected]}\" id=\"hidden_color_picker\"/>" 
    toret += "<div class=\"clear\"></div>" 
    toret += "</div>" 
    return toret
  end
end
  
