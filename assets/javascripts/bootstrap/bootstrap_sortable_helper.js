// Return a helper with preserved width of cells
var fixHelper = function(e, ui) {
  ui.children().each(function() {
    $(this).width($(this).width());
  });
  return ui;
};


function setSortableElement(element, form) {
  $(element).sortable({
    helper: fixHelper,
    axis: 'y',
    update: function(event, ui) {
      $.post($(form).data('update-url'), $(this).sortable('serialize'), null, 'script');
    }
  });
}
