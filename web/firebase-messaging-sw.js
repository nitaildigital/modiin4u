// Shows push notifications on the website while no tab of it is open.
//
// Firebase registers this file itself when the site asks for a token
// (lib/core/push/push_service.dart), under its own scope, beside Flutter's
// service worker rather than in its place. It draws the notification from the
// message's `notification` part, and a click opens `webpush.fcm_options.link`,
// both set by supabase/functions/push-dispatch.
//
// The config is the project's public web config — the same values as the
// `web` entry in lib/firebase_options.dart (project modiin4u-a895f, the
// client's) — and not a secret. Nothing registers this worker until the
// site has a VAPID key (lib/core/push/push_config.dart).
//
// The SDK version follows firebase_core_web's (supportedFirebaseJsSdkVersion).

importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAwPCi3eFuoponvqvf4cGlCu7nTuwHkOow',
  authDomain: 'modiin4u-a895f.firebaseapp.com',
  projectId: 'modiin4u-a895f',
  messagingSenderId: '643935084045',
  appId: '1:643935084045:web:bdf1bba4316f3759017f44',
});

firebase.messaging();
