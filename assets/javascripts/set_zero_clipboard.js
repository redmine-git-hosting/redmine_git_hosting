var zero_clipboard_source_input_control_id = "git_url_text";
function setZeroClipboardInputSource(id) {
  zero_clipboard_source_input_control_id = id;
}

var clipboard = null;
function setUpClipboard() {
  var clip_container = $('#clipboard_container');
  if (clip_container) {
    clip_container.show();
    clipboard = new ZeroClipboard($("#clipboard_button"));
    clipboard.on('mouseover', function (client, args) {
      clipboard.setText($('#' + zero_clipboard_source_input_control_id).val());
    });
  }
}

$(document).ready(function() {
  setUpClipboard();
});
