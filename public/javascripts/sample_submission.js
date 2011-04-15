$(document).ready(function() {

  $('#js_enabled').show();
  $('#js_disabled').hide();

  $.validator.addMethod("noSpaces", function(value, element) {
    return !/\s/.test(value);
  }, "No spaces are allowed in this field");

  $("form").formwizard({ 
    formPluginEnabled: true,
    validationEnabled: true,
    focusFirstInput: true,
    inDuration: 200,
    outDuration: 200,
    disableUIStyles: true,
    formOptions: {
      success: function(data){
        $('#error').hide();
        $('form').hide();
        $('#success').show();
      },
      error: function(data) { submissionError(data); },
      beforeSubmit: function(data){$("#data").html("data sent to the server: " + $.param(data));},
      dataType: 'json'
    }
  });

  function submissionError(data) {
    $('#ErrorExplanation>p').replaceWith( '<p>' + JSON.parse(data.responseText).message + '</p>');
    $('#ErrorExplanation').show();
  }

  $('form').bind('step_shown', function(event, data) {
    if(data.currentStep == "samples") {
      generate_samples_form();
    }
    if(data.previousStep == "samples") {
      remove_samples_form();
    }
  });

  function generate_samples_form() {
    var project_id, number_of_samples, service_option_id, naming_scheme_id, params;

    project_id = $('#sample_set_project_id').attr('value');
    naming_scheme_id = $('#sample_set_naming_scheme_id').attr('value');
    number_of_samples = $('#sample_set_number').attr('value');
    service_option_id = $('#sample_set_service_option_id').attr('value');
    chip_type_id = $('#sample_set_chip_type_id').attr('value');
    already_hybridized = $('#sample_set_already_hybridized').attr('checked');

    params = {};
    if(project_id && project_id !== "") {
      params.project_id = project_id;
    }
    if(naming_scheme_id && naming_scheme_id !== "") {
      params.naming_scheme_id = naming_scheme_id;
    }
    if(number_of_samples) {
      params.number_of_samples = number_of_samples;
    }
    if(service_option_id && service_option_id !== "") {
      params.service_option_id = service_option_id;
    }
    if(chip_type_id && chip_type_id !== "") {
      params.chip_type_id = chip_type_id;
    }
    if(already_hybridized && already_hybridized !== "") {
      params.already_hybridized = already_hybridized;
    }

    $.ajax({ // add a remote ajax call when moving next from the second step
      url : "sample_fields", 
      dataType : 'html',
      data: {
        sample_set: params
      },
      type: 'GET',
      success : function(data){
        $('#sample_fields_loading').hide();
        $('#sample_fields').replaceWith(data);
        return true; //return true to make the wizard move to the next step
      }
    });
  }

  function remove_samples_form() {
    $('#sample_fields_loading').show();
    $('#sample_fields').replaceWith('<div id="sample_fields"></div>');
  }

  function setup_fields() {
  }

  setup_fields();

});
