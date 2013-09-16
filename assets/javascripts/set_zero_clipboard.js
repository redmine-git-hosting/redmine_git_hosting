var zero_clipboard_source_input_control_id = "git_url_text";

function setZeroClipboardInputSource(id) {
  zero_clipboard_source_input_control_id = id;
}

var button      = null;
var source_text = null;
var clipboard   = null;

function setUpClipboard() {
  var clip_container = document.getElementById('clipboard_container');
  if (clip_container) {
    clip_container.style.display = "";
    var button      = document.getElementById('clipboard_button');
    var clipboard   = new ZeroClipboard(button);

    clipboard.on('mouseover', function (client, args) {
      var source_text = document.getElementById(zero_clipboard_source_input_control_id).value;
      clipboard.setText(source_text);
    });
  }
}
