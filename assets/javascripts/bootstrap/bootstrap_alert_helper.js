/*
BootstrapAlert
*/
function setBootstrapAlert(){
  $('.alert').each(function(index, element){
    $(element).alert();
  });
}

function addAlertMessage(object){
  $(object.target)
    .append(
      $('<div>')
        .attr('class', 'alert fade in ' + object.type)
        .html(object.message)
        .prepend(
          $('<button>')
            .attr('class', 'close')
            .attr('type', 'button')
            .attr('data-dismiss', 'alert')
            .html('&times;')
        )
    )

  setBootstrapAlert();
}
