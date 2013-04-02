jQuery.noConflict();

var clipboard = null;

function reset_zero_clipboard() {
  var clip_container = jQuery('#clipboard_container');
  if (clip_container) {
    clip_container.show();

    //~ var cur_children = clip_container.childNodes;
    //~ var ci;
    //~ for(ci=0; ci< cur_children.length; ci++) {
      //~ var c = cur_children[ci];
      //~ if(c.id != "clipboard_button") {
        //~ clip_container.removeChild(c);
      //~ }
    //~ }

    clipboard = new ZeroClipboard.Client();
    clipboard.glue('clipboard_button', 'clipboard_container');
    clipboard.addEventListener('mouseOver', function (client) {
      clipboard.setText(document.getElementById('git_url_text').value);
    });
  }
}

jQuery(document).ready(function() {
  reset_zero_clipboard();
});
