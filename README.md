<p>
  <img src="../master/iOS/TNChat/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60%403x.png" alt="AFNetworking" title="AFNetworking">
</p>

# TNChat

TNChat is an open source chat project for iOS that uses Firebase as the backend to perform realtime chat functionality.
The main goal of this project is to explore Firebase's realtime database feature in a messaging app.
Other goals and challenges in this project are using CoreData to cache conversations and messages.
Another minor feature that is interesting is sending silent notifications from Firebase and handling them locally on the device.

The project also includes Firebase' Cloud Function feature, which is used to populate messages in the database to suit the app's needs.
The Cloud Function is also used to send silent push notifications to the client, which in its turn parses them, and schedules a local notification with the title being the name of the contact holding the sender's phone number.

## How to test
1. Create your own app in the [Firebase Console](https://console.firebase.google.com).
2. Enable Cloud Functions from Firebase Console.
3. Create and download the `GoogleService-Info.plist` file, and add it to the project.
4. Create APNS certificates and upload them to the Firebase Console.
5. Make sure you set the proper Bundle Identifier for the app and the rest of the Xcode account info.
6. Run the app on multiple devices and have fun!

## Summary
In this project, you can learn the following:
- [X] Firebase Realtime-Database & Cloud Functions.
- [X] Firebase SMS Authentication.
- [X] Silent Notifications and Scheduling Local Notifications on iOS.
- [X] CoreData's NSFetchedResultsController and other features.
- [X] Building a Chat UI for iOS.

## TODO
- [ ] Add `Delivered` and `Read` indicator.
- [ ] Add the ability to delete messages, and conversations.
- [ ] Add the ability to forward messages.
- [ ] Add group conversations.
- [ ] Turn the Chat UI into a **Cocoapod**!

## License
TNChat is released under the MIT license. See LICENSE for details.
