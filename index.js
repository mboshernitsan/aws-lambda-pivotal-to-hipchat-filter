// dependencies
var config = require('./config');
var util = require('util');

var HipChat = require('hipchatter');
var hipchatter = new HipChat();

exports.handler = (function(event, context) {
	var skip = false, bgcolor = 'yellow';

	switch (event.kind) {
		case "task_create_activity": 
		case "comment_create_activity":
			skip = false;
			bgcolor = 'gray';
			break;

		case "story_create_activity":
		case "story_delete_activity":
			skip = false;
			bgcolor = 'yellow';
			break;

		case "story_update_activity":
			skip = true;
			for (var i = 0; i < event.changes.length; i++) {
				var change = event.changes[i];
				// skip non-story changes
				if (change.kind != 'story') {
					continue;
				}
				// iterate over changed fields to determine if we care
				for (field in change.new_values) {
					switch (field) {
						case "current_state":
							switch (change.new_values.current_state) {
								case "accepted":
									bgcolor = 'green';
									break;
								case "rejeceted":
									bgcolor = 'red';
									break;
							}
							skip = false;
							break;
						case "estimate":
							bgcolor = 'gray';
							skip = false;
							break;
					}
				}
			}
			break;


		case "story_c2genericcommand_activity":

		case "epic_create_activity":
		case "epic_delete_activity":
		case "epic_update_activity":
		case "epic_move_activity":

		case "comment_delete_activity": 
		case "comment_update_activity":

		case "follower_create_activity":
		case "follower_delete_activity": 

		case "iteration_update_activity":

		case "label_create_activity":
		case "label_delete_activity":
		case "label_update_activity":
		
		case "project_membership_create_activity":
		case "project_membership_delete_activity":
		case "project_membership_update_activity":
		case "project_update_activity":

		case "story_move_activity":
		case "story_move_from_project_activity":
		case "story_move_into_project_activity":
		case "story_move_into_project_and_prioritize_activity":

		case "task_delete_activity": 
		case "task_update_activity":
			skip = true;
			break;
	}

	if (skip) {
		context.done(null, { "status":"skipped"});
		return;
	}


	// creation message and options
	var msg = {
		token : config.apiAuthToken,
		message_format : "html",
		color : bgcolor,
		notify : false,
		message : event.message
	};


	if (event.primary_resources.length == 1) {
		var resource = event.primary_resources[0];

		// resolve indefinite phrase in message
		msg.message = msg.message.replace(/this (feature|epic|bug|chore|release)/g, 
			util.format("%s: \"%s\"", (resource.kind == "story" ? resource.story_type : resource.kind), resource.name));

		// append Pivotal URL
		msg.message += util.format(" <a href=%s>view »</a>", resource.url);
	}	
	
	// send message
	hipchatter.notify(config.roomId, msg, function(err) {
		if (err) {
			throw err;
		} else {
		  	context.done(null, {"status":"sent"});
		}
	});
});
