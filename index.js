// dependencies
var config = require('./config');
var util = require('util');

var HipChatClient = require('hipchat-client');
var hipchat = new HipChatClient(config.apiAuthToken);

exports.handler = (function(event, context) {
	
	// creation message and options
	var msg = {
		room_id : config.roomId,
		from : "Pivotal",
		message_format : "html",
		color : "yellow",
		notify : false,
		message : event.message
	};


	if (event.primary_resources.length == 1) {
		var resource = event.primary_resources[0];

		// resolve indefinite phrase in message
		msg.message = msg.message.replace(/this (feature|epic|bug|chore|release)/g, util.format("%s: \"%s\"", (resource.kind == "story" ? resource.story_type : resource.kind), resource.name));

		// append Pivotal URL
		msg.message += util.format(" <a href=%s>view »</a>", resource.url);
	}	
	
	// send message
	hipchat.api.rooms.message(msg, function(err, res) {
		if (err) {
			throw err;
		}

		console.log(res);

	  context.done();
	});
});
