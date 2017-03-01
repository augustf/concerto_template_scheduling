// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function attachConcertoTemplateSchedulingHandlers() {
  $('select#schedule_config_display_when').on('change', toggleCtsFormFields);

  function toggleCtsFormFields() {
    var dw = $('select#schedule_config_display_when').val();
    if (dw == 3) {  // 'content exists'
      $('#feed_selection').show();
      $('#scheduling_criteria').hide();
    } else if (dw == 2) {  // 'by criteria'
      $('#feed_selection').hide();
      $('#scheduling_criteria').show();
    } else {
      $('#feed_selection').hide();
      $('#scheduling_criteria').hide();
    }
  }

  toggleCtsFormFields();
}

$(document).on('turbolinks:load', attachConcertoTemplateSchedulingHandlers);
