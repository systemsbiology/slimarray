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
      if( s.length == 1) window.location.assign("/samples/" + s + "/edit");
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
        $('<form method="post" action="' + "/samples/" + s + '" />')
            .append('<input type="hidden" name="_method" value="delete" />')
            .appendTo('body')
            .submit();

        return false;
    } 
  }); 
});
 
