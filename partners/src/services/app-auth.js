'use strict';

import { getAuth, signInAnonymously, linkWithCredential, onAuthStateChanged, RecaptchaVerifier, signInWithPhoneNumber, signOut, PhoneAuthProvider } from 'firebase/auth';

const ngModule = angular.module('services.app-auth', [])

	.factory('appAuth', function () {

		return {
			getAuth: getAuth,
			onAuthStateChanged: onAuthStateChanged,
			signInWithPhoneNumber: signInWithPhoneNumber,
			RecaptchaVerifier: RecaptchaVerifier,
			signInAnonymously: signInAnonymously,
			signOut: signOut,
			PhoneAuthProvider: PhoneAuthProvider,
			linkWithCredential: linkWithCredential
		}
	})

export default ngModule;