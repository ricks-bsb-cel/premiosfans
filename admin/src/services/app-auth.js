'use strict';

import { getAuth, signInAnonymously, GoogleAuthProvider, signInWithRedirect, signOut, onAuthStateChanged, signInWithEmailAndPassword } from 'firebase/auth';

const ngModule = angular.module('services.app-auth', [])

	.factory('appAuth', function () {

		return {
			getAuth: getAuth,
			GoogleAuthProvider: GoogleAuthProvider,
			signInWithRedirect: signInWithRedirect,
			signOut: signOut,
			onAuthStateChanged: onAuthStateChanged,
			signInWithEmailAndPassword: signInWithEmailAndPassword,
			signInAnonymously: signInAnonymously
		}
	})

export default ngModule;