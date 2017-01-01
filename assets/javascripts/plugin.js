/*
REDMINE PLUGIN LIST VIEW OVERRIDE
*/
function openAuthorModalBox(element) {
  $('#ajax-modal').dialog({
    resizable: false,
    autoOpen: false,
    height: 'auto',
    width: 'auto',
    modal: true,
    hide: {
      effect: "fade",
      duration: 500
    },
    buttons: { Ok: function(){ $(this).dialog('close'); } }
  });

  var title = $(element).html();
  $.get($(element).attr('href'), function(data){
    $('#ajax-modal').html(data);
    $('#ajax-modal').dialog('option', 'title', title);
    $('#ajax-modal').dialog('open');
  });
}

function enhanceAuthorsUrlForPlugin(plugin_name) {
  var link = $('#plugin-' + plugin_name + ' > td.author > a');
  if (link.length) {
    link.addClass('modal-box');
    $(document).on('click', 'a.modal-box', function(e){
      e.preventDefault();
      openAuthorModalBox(this);
    });
  }
}

$(document).ready(function() {
  enhanceAuthorsUrlForPlugin('redmine_git_hosting');
});
