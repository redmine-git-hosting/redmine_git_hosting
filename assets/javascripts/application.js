function post_mode_change(element) {
  if (!element) return;
  var idx = element.selectedIndex;
  if (idx == 0) {
    $('#payload_options').show();
  } else {
    $('#payload_options').hide();
  }
}

function push_mode_change(element) {
  if (!element) return;
  var idx = element.selectedIndex;
  if (idx == 0) {
    $('#ref_spec_options').hide();
  } else {
    $('#ref_spec_options').show();
  }
}

function key_mode_change(element) {
  if (!element) return;
  var idx = element.selectedIndex;
  if (idx == 0) {
    $('#new_key_window').show();
  } else {
    $('#new_key_window').hide();
  }
}

function trigger_mode_change(element) {
  element = $('#'+element.id);
  if(element.is(":checked")) {
    $('#triggers_options').show();
  } else {
    $('#triggers_options').hide();
  }
}


// REPOSITORY EDIT
function setRepositoryActiveTab(current_tab) {
  var all_tabs = $("#repository-tabs li");
  var active_tab = '';

  all_tabs.each(function(){
    if ($(this).attr('id').replace('tab-', '') == current_tab) {
      active_tab = all_tabs.index(this);
    }
  });

  $("#repository-tabs").tabs({
    active: active_tab,
    activate: function(event, ui) {
      var new_tab_name = $(ui.newTab).attr('id').replace('tab-', '');
      if ("replaceState" in window.history) {
        window.history.replaceState(null, document.title, 'edit?tab=' + new_tab_name);
      }
    }
  });
}

function setSettingsActiveTab() {
  groups = $('[id^=tab-gitolite_]');

  $.each(groups, function(key, elem) {
    $(elem).on('click', function(){
      if ("replaceState" in window.history) {
        window.history.replaceState(null, document.title, 'redmine_git_hosting?tab=' + $(this).attr('id').replace('tab-', ''));
      }
    });
  });
}

function displayWarning(){
  var checked_list = $(".empty_trash:checked");
  if(checked_list.length === 0){
    $('#delete_warning').hide();
  } else {
    $('#delete_warning').show();
  }
}

function setRecycleBinWarnings() {
  $("#select_all_delete").on('click', function(){
    $('.empty_trash').each(function(){
      $(this).attr('checked', !$(this).attr('checked'));
      displayWarning();
    });
  });

  $(".empty_trash").on('change', function(){
    displayWarning();
  });
}
