
const ngModule = angular.module('directives.file-upload', [])

	.directive('fileUpload', function (
		appStorage
	) {
		return {
			restrict: 'A',
			scope: true,
			link: function (scope, element, attr) {

				element.bind('change', function () {
					let file = element[0].files[0];

					/*
					var formData = new FormData();
					formData.append('file', element[0].files[0]);
					*/

					// https://firebase.google.com/docs/storage/web/upload-files?hl=pt-br
					debugger;

					const storageRef = appStorage.ref(appStorage.storage, 'teste/some-child.jpg');
					const uploadTask = uploadBytesResumable(storageRef, file);

					uploadTask.on('state_changed',
						snapshot => {
							// Observe state change events such as progress, pause, and resume
							// Get task progress, including the number of bytes uploaded and the total number of bytes to be uploaded
							const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
							console.log('Upload is ' + progress + '% done');
							switch (snapshot.state) {
								case 'paused':
									console.log('Upload is paused');
									break;
								case 'running':
									console.log('Upload is running');
									break;
							}
						},
						error => {
							console.error(error);
						},
						_ => {
							// Handle successful uploads on complete
							appStorage.getDownloadURL(uploadTask.snapshot.ref).then(downloadURL => {
								console.log('File available at', downloadURL);
							});
						}
					);

					// 'file' comes from the Blob or File API
					appStorage.uploadBytes(storageRef, file).then((snapshot) => {
						console.log('Uploaded a blob or file!');
					})


				});

			}
		};
	});

export default ngModule;
