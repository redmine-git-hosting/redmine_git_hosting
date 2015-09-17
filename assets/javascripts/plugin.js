// Bind links on Dialog box
function initModalBox() {
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
    buttons: {
      Ok: function(){$(this).dialog('close');}
    }
  });

  $('.modal-box').each(function() {
    $(this).on('click', function() {
      var title = $(this).html();
      $.get($(this).attr('href'), function(data){
        $('#ajax-modal').html(data);
        $('#ajax-modal').dialog('option', 'title', title);
        $('#ajax-modal').dialog('open');
      });
      return false;
    });
  });
}

function enhanceAuthorsUrlForPlugin(plugin_name) {
  var link = $('#plugin-' + plugin_name + ' > td.author > a');
  if (link.length) {
    link.addClass('modal-box');
    initModalBox();
  }
}

$(document).ready(function() {
  enhanceAuthorsUrlForPlugin('redmine_git_hosting');
});
