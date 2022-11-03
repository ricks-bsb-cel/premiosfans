'use strict';

import appService from './app';
import firebaseInit from './firebase/firebase.config';
import googleApis from './google-apis/google-apis';

import firebaseCollections from './firebase/tables/firebase.collections';

import app from './app';
import appErrors from './app-errors';
import appAuth from './app-auth';
import appAuthHelper from './app-auth-helper';
import appFirestore from './app-firestore';
import appFirestoreHelper from './app-firestore-helper';
import appDatabase from './app-database';
import appDatabaseHelper from './app-database-helper';
import appStorage from './app-storage';
import appCollection from './app-collection';
import appConfig from './app-config';

import utils from './utils';

let ngModule = angular.module('services',
	[
		// serviceFirebase.name,
		appService.name,
		firebaseInit.name,
		googleApis.name,
		
		app.name,
		appErrors.name,
		appAuth.name,
		appAuthHelper.name,
		appFirestore.name,
		appFirestoreHelper.name,
		appDatabase.name,
		appService.name,
		appDatabaseHelper.name,
		appCollection.name,
		appStorage.name,
		appConfig.name,
		
		firebaseCollections.name,

		utils.name
	]
);

export default ngModule;
