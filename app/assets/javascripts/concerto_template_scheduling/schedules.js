// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var ConcertoTemplateScheduling = {
  _initialized: false,

  toggleCtsFormFields: function () {
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
  },

  initHandlers: function () {
    if (!ConcertoTemplateScheduling._initialized) {
      $(document).on('change', 'select#schedule_config_display_when', ConcertoTemplateScheduling.toggleCtsFormFields);
    }
    ConcertoTemplateScheduling.toggleCtsFormFields();
    ConcertoTemplateScheduling._initialized = true;
  }
};

$(document).ready(ConcertoTemplateScheduling.initHandlers);
$(document).on('turbolinks:load', ConcertoTemplateScheduling.initHandlers);
