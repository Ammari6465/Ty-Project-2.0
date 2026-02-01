importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyAKhl_U_wtWQW7QrPAqHcKJ8aWghIAHKAo",
  authDomain: "disaster-link-ec682.firebaseapp.com",
  projectId: "disaster-link-ec682",
  storageBucket: "disaster-link-ec682.firebasestorage.app",
  messagingSenderId: "480593223354",
  appId: "1:480593223354:web:0b439feb35c27ea0696c83",
  measurementId: "G-RPCQQ333M6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});