function createZeroClipBoard(object){
  ZeroClipboard.config({ swfPath: object.movie_path });
  var client = new ZeroClipboard($(object.target));

  client.on('ready', function() {
    $('#global-zeroclipboard-html-bridge').tooltip({
      title:     object.label_to_copy,
      placement: 'right'
    });

    client.on('beforecopy', function() {
      $('#global-zeroclipboard-html-bridge').tooltip('show');
    });

    client.on('aftercopy', function() {
      $('.tooltip .tooltip-inner').text(object.label_copied);
    });
  });
}
