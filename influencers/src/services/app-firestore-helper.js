'use strict';

const ngModule = angular.module('services.firestore-helper', [])

	.service('appFirestoreHelper', function (
		appFirestore
	) {

		const currentTimestamp = _ => {
			return appFirestore.Timestamp.now();
		}

		const currentTimeStampAsSeconds = _ => {
			const timestamp = currentTimestamp();
			return parseFloat(timestamp.seconds + '.' + timestamp.nanoseconds);
		}

		const currentTimestampAsMoment = _ => {
			const timestamp = currentTimestamp();
			return toMoment(timestamp);
		}

		const startTimestamp = () => {
			return appFirestore.Timestamp.fromDate(new Date(2000, 0, 1));
		}

		const toTimestamp = (value) => {
			return appFirestore.Timestamp.fromDate(value);
		}

		const toMoment = timestamp => {
			return moment(timestamp.toDate());
		}

		const doc = (c, id) => {
			return appFirestore.doc(appFirestore.firestore, c, id);
		}

		return {
			currentTimestamp: currentTimestamp,
			currentTimeStampAsSeconds: currentTimeStampAsSeconds,
			currentTimestampAsMoment: currentTimestampAsMoment,
			startTimestamp: startTimestamp,
			toTimestamp: toTimestamp,
			doc: doc,
			toMoment: toMoment
		}

	})

export default ngModule;
