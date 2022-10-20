const functions = require("firebase-functions");

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/* Módulo de Administração */
exports.mainAdm = functions.https.onRequest(require("./admin/httpCalls").mainAdm);



/*
// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyCAWlJXzEptl2TJ8J4CWeBUaA15o-hSqSs",
  authDomain: "premios-fans.firebaseapp.com",
  databaseURL: "https://premios-fans-default-rtdb.firebaseio.com",
  projectId: "premios-fans",
  storageBucket: "premios-fans.appspot.com",
  messagingSenderId: "801994869227",
  appId: "1:801994869227:web:188d640a390d22aa4831ae",
  measurementId: "G-XTRQ740MSL"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
*/