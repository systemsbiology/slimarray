$(document).ready(function(){
  $("#bedata").click(function(){
    var s; s = jQuery("#data_grid").getGridParam('selarrrow');
    if( s == null || s.length == 0 ) alert("Please select a row to edit");
    else if( s.length == 1) window.location.assign(location.href + "/" + s + "/edit");
    else alert("Only one record can be edited at a time");
  }); 

  $("#bddata").click(function(){
    var s; s = jQuery("#data_grid").getGridParam('selarrrow');
    if( s == null || s.length == 0 ) alert("Please select a row to destroy");
    else if(s.length == 1) {
      if( confirm("Are you sure you want to delete this record?") ) {
        $('<form method="post" action="' + location.href + "/" + s + 'json" />')
            .append('<input type="hidden" name="_method" value="delete" />')
            .appendTo('body')
            .submit();

        return false;
      }
    } else {
      if( confirm("Are you sure you want to delete these records?") ) {
        s.forEach( function(id) {
          $.post(location.href + "/" + id + ".json", {asynchronous: false, _method: 'delete'},
            function() {
              $("#data_grid").trigger("reloadGrid", [{current:true}]);
            });
        });

        return false;
      }
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
    else if( s.length == 1 ) {
      if( confirm("Are you sure you want to delete this sample?") )
        $('<form method="post" action="' + samples_url + "/" + s + '" />')
            .append('<input type="hidden" name="_method" value="delete" />')
            .appendTo('body')
            .submit();

        return false;
    } else {
      if( confirm("Are you sure you want to delete these samples?") ) {
        s.forEach( function(id) {
          $.post(samples_url + "/" + id + ".json", {asynchronous: false, _method: 'delete'},
            function() {
              $("#sample_grid").trigger("reloadGrid", [{current:true}]);
            });
        });

        return false;
      }
    }
  }); 

  $(".bulk_handle_button").click(function(){
    var s; s = jQuery("#data_grid").getGridParam('selarrrow');
    if( s == null || s.length == 0 ) alert("Please select one or more rows");
    else {
      var selection_fields = "";
      s.forEach( function(id) {
        selection_fields += '<input type="hidden" name="selected_hybridizations[' + id + ']" value="1" />'
      });
      $('<form method="post" action="' + location.href + '/bulk_handler" />')
          .append(selection_fields)
          .append('<input type="hidden" value="' + $(this)[0].value + '" name="commit"/>')
          .appendTo('body')
          .submit();
    } 
  });

  $('#sample_set_chip_type_id').change(function() {
    var sel = $("#sample_set_chip_type_id option:selected")[0].value;

    if(sel) {
      $.get('../chip_types/' + sel + '/service_options', function(data) {
        $('#sample_set_service_options').html(data);
      });
    }
  });

  $('#sample_set_service_options').change(function() {
    var price, number, total;

    price = $("#sample_set_service_option_id option:selected").attr('price');
    number = $('#sample_set_number_of_samples').attr('value');
    total = "$" + price * number;

    $('#cost_estimate').html(total);
  });
});
 
