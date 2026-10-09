// Shows push notifications on the website while no tab of it is open.
//
// The site registers this file when a visitor turns notifications on
// (src/lib/push.ts), at the address and scope the Flutter site used, so a
// browser the old site registered keeps receiving. It draws the notification
// from the message's `notification` part, and a click opens
// `webpush.fcm_options.link`, both set by supabase/functions/push-dispatch.
//
// The config is the project's public web config — the same values as
// web/firebase-messaging-sw.js for the Flutter build (project modiin4u-a895f,
// the client's) — and not a secret.

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
