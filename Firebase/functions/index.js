const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

exports.sendMessageNotification = functions.database.ref('chats/{chatID}/messages/{messageID}').onWrite(event => {
	if (!event.data.exists()) {
		return;
	};

	admin.database().ref("chats/"+event.params.chatID+"/participants").once('value').then(function(participantsSnap) {
		const message = event.data.val();
		const participants = participantsSnap.val();
		const user1 = participants[0]; // first user id
		const user2 = participants[1]; // second user id

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
			var payload = {
				notification: {
					title: title,
					body: message.message,
					sender: message.user
				}
			};

			admin.messaging().sendToTopic(topic, payload)
				.then(function(response) {
			})
			.catch(function(error) {
				console.log("Error sending message:", error);
			});
		});
	});
});