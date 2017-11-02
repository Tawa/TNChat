# TNChat

TNChat is an open source chat project for iOS that uses Firebase as the backend to perform realtime chat functionality.
The main goal of this project is to explore Firebase's realtime database feature in a messaging app.
Other goals and challenges in this project are using CoreData to cache conversations and messages.
Another minor feature that is interesting is sending silent notifications from Firebase and handling them locally on the device.

The project also includes Firebase' Cloud Function feature, which is used to populate messages in the database to suit the app's needs.
The Cloud Function is also used to send silent push notifications to the client, which in its turn parses them, and schedules a local notification with the title being the name of the contact holding the sender's phone number.

## Summary
In this project, you can learn the following:
1. Firebase Realtime-Database & Cloud Functions.
2. Firebase SMS Authentication.
3. Silent Notifications and Scheduling Local Notifications on iOS.
4. CoreData's NSFetchedResultsController and other features.
5. Building a Chat UI for iOS.
