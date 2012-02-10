// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function set_color_picker(element_name,color){
    items = document.getElementsByClassName('coloritem');
    for(x=0;x<items.length;x++){
        Element.removeClassName(items[x],'cpselected');
    }
    Element.addClassName(element_name,'cpselected')
    document.getElementById('hidden_color_picker').value = color
}