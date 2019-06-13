/*
BootstrapTooltips
*/
function setBootstrapToolTips(){
  $('.tooltips').tooltip({
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
}
