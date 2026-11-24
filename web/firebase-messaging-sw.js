/* The Atlas Academy background push handler. */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAP0bj6z-wf15cMaCkHFDa4_vynxL0H5HM',
  authDomain: 'the-atlas-academy-3fae0.firebaseapp.com',
  projectId: 'the-atlas-academy-3fae0',
  storageBucket: 'the-atlas-academy-3fae0.firebasestorage.app',
  messagingSenderId: '299084089644',
  appId: '1:299084089644:web:f93b049f91507eb68f0489',
  measurementId: 'G-772L3XLBKQ'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'The Atlas Academy';
  const options = {
    body: payload.notification?.body || 'You have a new academy notification.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
    tag: payload.data?.notificationId || 'atlas-academy-notification',
    renotify: true
  };
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const windows = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of windows) {
      if ('focus' in client) {
        await client.focus();
        return;
      }
    }
    await clients.openWindow('/');
  })());
});
