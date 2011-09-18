var zero_clipboard_source_input_control_id = "git_url_text";
var clipboard = null

function reset_zero_clipboard()
{
	var clip_container = $('clipboard_container');
	if (clip_container) {
		clip_container.show();
		clip_container.style.fontFamily="serif"

		var cur_children = clip_container.childNodes;
		var ci;
		for(ci=0; ci< cur_children.length; ci++)
		{
			var c = cur_children[ci];
			if(c.id != "clipboard_button")
			{
				clip_container.removeChild(c);
			}
		}

		clipboard = new ZeroClipboard.Client();

		clipboard.setHandCursor(true);
		clipboard.glue('clipboard_button', 'clipboard_container');

		clipboard.addEventListener('mouseOver', function (client) {
			clipboard.setText($(zero_clipboard_source_input_control_id).value);
		});
	}
}

function setZeroClipboardInputSource(id)
{
	zero_clipboard_source_input_control_id = id;
}

document.observe("dom:loaded", function() { reset_zero_clipboard(); } )
