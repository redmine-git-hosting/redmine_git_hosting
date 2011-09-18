var zero_clipboard_source_input_control_id = "git_url_text";

document.observe("dom:loaded", function() {
	var clip_container = $('clipboard_container');
	if (clip_container) {
		clip_container.show();

		clipboard = new ZeroClipboard.Client();

		clipboard.setHandCursor(true);
		clipboard.glue('clipboard_button', 'clipboard_container');

		clipboard.addEventListener('mouseOver', function (client) {
			clipboard.setText($(source_input_control_id).value);
		});
	}
});

function setZeroClipboardInputSource(id)
{
	zero_clipboard_source_input_control_id = id;
}


