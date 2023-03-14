
import 'api-check/dist/api-check';

import formly from 'angular-formly';
import formlyBootstrap from 'angular-formly-templates-bootstrap';

import config from './config';

import url from './url/url';
import telefone from './telefone/telefone';
import email from './email/email';
import range from './range/range';
import radios from './radios/radios';
import customCheckbox from './custom-checkbox/custom-checkbox';
import reais from './reais/reais';
import integer from './integer/integer';
import ngSelector from './ng-selector/ng-selector';
import maskPattern from './mask-pattern/mask-pattern';
import maskNumber from './mask-number/mask-number';
import data from './data/data';
import cpf from './cpf/cpf';
import cnpj from './cnpj/cnpj';
import celular from './celular/celular';
import cpfcnpj from './cpfcnpj/cpfcnpj';
import ngSelectorEstado from './ng-selector-estado/ng-selector-estado';
import imageUpload from './image-upload/image-upload';

const ngModule = angular
	.module(
		'app.formly',
		[
			formly,
			formlyBootstrap,

			url.name,
			telefone.name,
			integer.name,
			email.name,
			range.name,
			radios.name,
			customCheckbox.name,
			reais.name,
			ngSelector.name,
			maskPattern.name,
			maskNumber.name,
			data.name,
			cpf.name,
			cnpj.name,
			cpfcnpj.name,
			celular.name,
			ngSelectorEstado.name,
			imageUpload.name
		]
	)

	.factory('formlyFactory', function (
		appStorage,
		alertFactory,
		toastrFactory,
		$timeout
	) {

		const toLowerCase = value => {
			return (value || '').toLowerCase();
		}

		const toUpperCase = value => {
			return (value || '').toUpperCase();
		}

		// https://pqina.nl/slim/
		const slimCloudinary = attr => {

			var slim = null,
				initiated = false,
				didCancel = false,
				didConfirm = false,
				currentImage = null,
				previousImage = null;

			if (!attr.options.storage.filename) {
				throw new Error('Informe templateOptions.storage.filename!');
			}

			if (attr.options.storage.filename.split('.').pop() !== attr.options.storage.filename) {
				throw new Error(`NÃO informe a extensão do arquivo no filename [${attr.options.storage.filename}]. Será utilizada a extensão original...`);
			}

			var defaultOptions = {
				instantEdit: false,
				edit: true,
				size: '512,512',
				ratio: "3:2",
				minSize: '512,512',
				push: true,
				label: "",
				statusUploadSuccess: "",
				labelLoading: "...",
				serviceFormat: "file",
				buttonCancelLabel: "Cancelar",
				buttonCancelTitle: "Cancelar",
				buttonConfirmLabel: "Salvar",
				buttonConfirmTitle: "Salvar",

				didInit: _ => {
					previousImage = currentImage;
					initiated = true;
				},

				didLoad: _ => {
					console.info('didLoad');

					if (initiated && !didCancel) {
						$timeout(function () {
							previousImage = currentImage;
							slim.edit();
						})
					}

					didCancel = false;
					didConfirm = false;

					if (typeof attr.didLoad == 'function') {
						attr.didLoad();
					}

					return true;
				},

				willRemove: _ => {
					alertFactory.yesno('Tem certeza que deseja remover este documento?').then(_ => {
						if (typeof attr.didRemove == 'function') {
							attr.didRemove();
						}
						slim.remove();
					})
				},

				didConfirm: _ => {
					console.info('didConfirm');

					didConfirm = true;

					if (typeof attr.didConfirm == 'function') {
						attr.didConfirm();
					}
				},

				didCancel: _ => {
					console.info('didCancel');

					didCancel = true;
					currentImage = previousImage;

					slim.load(previousImage);

					if (typeof attr.cancelCallback == 'function') {
						attr.cancelCallback(previousImage);
					}
				},

				service: (blobFile, progress, success, failure) => {

					if (!didConfirm) { return; }

					if (typeof attr.uploadStart === 'function') {
						attr.uploadStart();
					}

					let file = new File(blobFile, blobFile[0].name);
					let extension = file.name.split('.').pop().toLowerCase();
					let storageFileName = attr.options.storage.filename + '.' + extension;

					const storageRef = appStorage.ref(appStorage.storage, storageFileName);
					const uploadTask = appStorage.uploadBytesResumable(storageRef, file);

					uploadTask.on('state_changed',

						snapshot => {
							const progress = Math.round((snapshot.bytesTransferred / snapshot.totalBytes) * 100);

							if (typeof attr.uploadProgress === 'function') { attr.uploadProgress(progress); }

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
							if (typeof attr.uploadEnd === 'function') { attr.uploadEnd(); }
							console.error('(2)', error);
						},

						completed => {

							toastrFactory.info('Upload da imagem realizado com sucesso', 'Zoepay');

							if (typeof attr.uploadEnd === 'function') { attr.uploadEnd(storageRef.fullPath); }
							if (typeof attr.uploadedCallback === 'function') { attr.uploadedCallback(storageRef.fullPath); }

							/*
							appStorage.getDownloadURL(uploadTask.snapshot.ref)
								.then(downloadURL => {
									if (typeof attr.uploadedCallback === 'function') { attr.uploadedCallback(downloadURL); }
								})
								.catch(e => {
									console.error(e);
								})
							*/

						}
					);

					appStorage.uploadBytes(storageRef, file, { contentType: 'image/jpeg' })
						/*
						.then(snapshot => {
							console.info('uploadBytes.snapshot success', snapshot);
						})
						*/
						.catch(e => {
							if (typeof attr.uploadEnd === 'function') { attr.uploadEnd(); }
							console.error('(1)', e);
						})

					success(true);
				}
			};

			defaultOptions = angular.merge(defaultOptions, attr.options || {});

			if (!defaultOptions.size) { delete defaultOptions.size; }
			if (!defaultOptions.ratio) { delete defaultOptions.ratio; }
			if (!defaultOptions.minSize) { delete defaultOptions.minSize; }

			var e = document.getElementById(attr.elementId);
			slim = new Slim(e, defaultOptions);
			return slim;
		}

		return {
			toLowerCase: toLowerCase,
			toUpperCase: toUpperCase,
			slimCloudinary: slimCloudinary
		};

	})

	.config(config);

export default ngModule;
