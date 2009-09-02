$(document).ready(function(){
  $("#bedata").click(function(){
    var s; s = jQuery("#data_grid").getGridParam('selarrrow');
    if( s != null ) {
      if( s.length == 1) window.location.assign(location.href + "/" + s + "/edit");
      else alert("Only one record can be edited at a time");
    }
    else alert("Please select a row to edit");
  }); 

  $("#bddata").click(function(){
    var s; s = jQuery("#data_grid").getGridParam('selarrrow');
    if( s == null || s.length == 0 ) alert("Please select a row to destroy");
    else if( s.length > 1 ) alert("Only one record can be destroyed at a time");
    else {
      if( confirm("Are you sure you want to delete this record?") )
        $('<form method="post" action="' + location.href + "/" + s + '" />')
            .append('<input type="hidden" name="_method" value="delete" />')
            .appendTo('body')
            .submit();

        return false;
    } 
  }); 

  $("#besample").click(function(){
    var s; s = jQuery("#sample_grid").getGridParam('selarrrow');
    if( s != null ) {
      if( s.length == 1) window.location.assign(samples_url + "/" + s + "/edit");
      else alert("Only one record can be edited at a time");
    }
    else alert("Please select a row to edit");
  }); 

  $("#bdsample").click(function(){
    var s; s = jQuery("#sample_grid").getGridParam('selarrrow');
    if( s == null || s.length == 0 ) alert("Please select a row to destroy");
    else if( s.length > 1 ) alert("Only one record can be destroyed at a time");
    else {
      if( confirm("Are you sure you want to delete this record?") )
        $('<form method="post" action="' + samples_url + "/" + s + '" />')
            .append('<input type="hidden" name="_method" value="delete" />')
            .appendTo('body')
            .submit();

        return false;
    } 
  }); 

  $(".bulk_handle_button").click(function(){
    var s; s = jQuery("#data_grid").getGridParam('selarrrow');
    if( s == null || s.length == 0 ) alert("Please select one or more rows to destroy");
    else {
      var selection_fields = "";
      for each (var id in s) {
        selection_fields += '<input type="hidden" name="selected_hybridizations[' + id + ']" value="1" />'
      }
      $('<form method="post" action="' + location.href + '/bulk_handler" />')
          .append(selection_fields)
          .append('<input type="hidden" value="' + $(this)[0].value + '" name="commit"/>')
          .appendTo('body')
          .submit();
    } 
  });

});
 
