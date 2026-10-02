// Shows push notifications on the website while no tab of it is open.
//
// Firebase registers this file itself when the site asks for a token
// (lib/core/push/push_service.dart), under its own scope, beside Flutter's
// service worker rather than in its place. It draws the notification from the
// message's `notification` part, and a click opens `webpush.fcm_options.link`,
// both set by supabase/functions/push-dispatch.
//
// The config is the project's public web config — the same values as the
// `web` entry in lib/firebase_options.dart — and not a secret. Until it is
// filled in, nothing registers this worker: the site does not ask for
// notifications without a VAPID key (lib/core/push/push_config.dart).
//
// The SDK version follows firebase_core_web's (supportedFirebaseJsSdkVersion).

importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'FIREBASE_WEB_API_KEY',
  authDomain: 'FIREBASE_PROJECT_ID.firebaseapp.com',
  projectId: 'FIREBASE_PROJECT_ID',
  messagingSenderId: 'FIREBASE_MESSAGING_SENDER_ID',
  appId: 'FIREBASE_WEB_APP_ID',
});

firebase.messaging();
