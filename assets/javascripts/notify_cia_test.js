document.observe("dom:loaded", function() {
	console.log("Binding click event to test cia notification");
	Event.observe("notify_cia_test", 'click', function(event) {
		console.log("Notification Test Link Clicked");
		Event.stop(event);
		new Ajax.Request($('notify_cia_test').href, {
			onSuccess : function(transport) {
				console.log("Notification Test Result:", transport.responseText);
				$('notify_cia_result').update(transport.responseText)
			},
			onFailure : function(transport) {
				console.log("Notification Test Failure:", transport);
				$('notify_cia_result').update(transport.responseText);
			}
		})
		return false;
	})
})
