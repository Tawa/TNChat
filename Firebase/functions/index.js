const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

exports.sendPushNotification = functions.database.ref('chats/{chatID}/messages/{messageID}').onWrite(event => {
	if (!event.data.exists()) {
		return;
	};

	const message = event.data.val();
    const participants = chatID.split("&");
	const user1 = participants[0];
	const user2 = participants[1];

	admin.database().ref("userData/" + user1 + "/" + user2 + "/message").set(message);
	admin.database().ref("userData/" + user2 + "/" + user1 + "/message").set(message);

	var topic = user1;
	if (topic == message.user) {
		topic = user2;
	}

	admin.database().ref("names/"+message.user).once('value').then(function(nameSnap) {
		var title = "You have a new message";
		if (nameSnap.exists()) {
			title = nameSnap.val();
		}
		const payload = {
			notification: {
				title: title,
				body: message.message,
				sender: message.user
			}
		};

		const options = {
		    content_available: true
		};

		admin.messaging().sendToTopic(topic, payload, options)
			.then(function(response) {
			console.log("Message sent: ", response);
		})
		.catch(function(error) {
			console.log("Error sending message: ", error);
		});
	});
});