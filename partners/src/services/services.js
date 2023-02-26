'use strict';

import initFirebase from './firebase.config';

import appConfig from './app-config';
import appService from './app-service';
import appAuth from './app-auth';
import appFunctions from './app-functions';
import appAuthHelper from './app-auth-helper';
import appFirestore from './app-firestore';
import appFirestoreHelper from './app-firestore-helper';
import appDatabase from './app-database';
import appDatabaseHelper from './app-database-helper';
import appStorage from './app-storage';

import users from './users';
import profile from './profile';
import utils from './utils';

let ngModule = angular.module('services',
	[
		initFirebase.name,
		appConfig.name,
		appService.name,
		appAuth.name,
		appFunctions.name,
		appAuthHelper.name,
		appFirestore.name,
		appFirestoreHelper.name,
		appDatabase.name,
		appDatabaseHelper.name,
		appStorage.name,

		users.name,
		profile.name,
		utils.name
	]
);

export default ngModule;
