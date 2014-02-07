/*
BootstrapSwitch
*/
function setBootstrapSwitch() {
  $('.bootstrap-switch').each(function(index, element) {
    installBootstrapSwitch(element);
  });
}

function installBootstrapSwitch(element) {
  $(element).bootstrapSwitch();
  $(element).on('switch-change', function (e, data) {
    var element = $(data.el);
    var value   = data.value;
    element.val(value);
  });
}


/*
BootstrapTooltips
*/
function setBootstrapToolTips(){
  $('.tooltips').each(function(index, element) {
    $(element).tooltip({
      position: {
        my: "left+15 left",
        at: "right center",
        using: function( position, feedback ) {
          $(this).css(position);
          $('<div>')
            .addClass( 'arrow left' )
            .addClass( feedback.vertical )
            .addClass( feedback.horizontal )
            .appendTo( this );
        }
      }
    });
  });
}


/*
JQueryModalBox
*/
$(window).resize(function() {
  $(".ui-dialog-content").dialog("option", "position", ['center', 'center']);
});


// Transform div in Dialog box
function initModalBoxes(modals){

  $(modals.modal_list).each(function() {

    var buttons_list = {};

    if (this.mode == 'standard'){
      buttons_list[modals.label_save]   = function(){$(this).find('form').submit();};
      buttons_list[modals.label_cancel] = function(){$(this).dialog('close');};
    } else if (this.mode == 'close-only'){
      buttons_list[modals.label_ok] = function(){$(this).dialog('close');};
    }

    $(this.target).dialog({
      resizable: false,
      autoOpen: false,
      height: 'auto',
      width: 'auto',
      position: ['center', 'center'],
      modal: true,
      hide: {
        effect: "fade",
        duration: 500
      },
      buttons: buttons_list,
    });

    setUpModalBox(this.source, this.target);
  });
}


// Bind links on Dialog box
function setUpModalBox(source, target) {
  $(source).each(function() {
    $(this).on('click', function() {
      var title = $(this).html();
      $.get($(this).attr('href'), function(data){
        $(target).html(data);
        $(target).dialog('option', 'title', title);
        $(target).dialog('open');
      });
      return false;
    });
  });
}
