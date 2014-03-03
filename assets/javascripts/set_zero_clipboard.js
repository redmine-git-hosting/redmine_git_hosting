function createZeroClipBoard(object){
  ZeroClipboard.config({ moviePath: object.movie_path });
  var client = new ZeroClipboard($(object.target));

  $('#global-zeroclipboard-html-bridge').tooltip({
    title:     object.label_to_copy,
    placement: 'right'
  });

  client.on('mouseover', function() {
    $('#global-zeroclipboard-html-bridge').tooltip('show');
  });

  client.on('complete', function() {
    $('.tooltip .tooltip-inner').text(object.label_copied);
  });
}
