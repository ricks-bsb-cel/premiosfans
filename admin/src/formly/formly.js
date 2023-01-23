
import '../../node_modules/api-check/dist/api-check';

import formly from '../../node_modules/angular-formly';
import formlyBootstrap from '../../node_modules/angular-formly-templates-bootstrap';

import config from './config';

import googleAutocomplete from './google-auto-complete/google-auto-complete';
import googleMapsPosition from './google-map-position/google-map-position';
import faIcon from './fa-icon/fa-icon';
import url from './url/url';
import telefone from './telefone/telefone';
import email from './email/email';
import range from './range/range';
import colorPicker from './color-picker/color-picker';
import imageUpload from './image-upload/image-upload';
import radios from './radios/radios';
import customCheckbox from './custom-checkbox/custom-checkbox';
import reais from './reais/reais';
import htmlEditor from './html-editor/html-editor';
import simpleList from './simple-list/simple-list';
import integer from './integer/integer';
import ngSelector from './ng-selector/ng-selector';
import maskPattern from './mask-pattern/mask-pattern';
import maskNumber from './mask-number/mask-number';
import data from './data/data';
import dataMMYYYY from './data-mm-yyyy/data-mm-yyyy';
import dataDD from './data-dd/data-dd';
import cpf from './cpf/cpf';
import cnpj from './cnpj/cnpj';
import celular from './celular/celular';
import cpfcnpj from './cpfcnpj/cpfcnpj';
import empresa from './empresa/empresa';
import checkboxPlanos from './checkbox-planos/checkbox-planos';

import ngSelectorCliente from './ng-selector-cliente/ng-selector-cliente';
import ngSelectorPlano from './ng-selector-plano/ng-selector-plano';
import ngSelectorContrato from './ng-selector-contrato/ng-selector-contrato';
import ngSelectorEstado from './ng-selector-estado/ng-selector-estado';
import ngSelectorEmpresa from './ng-selector-empresa/ng-selector-empresa';
import ngSelectorPerfis from './ng-selector-perfis/ng-selector-perfis';
import ngSelectorTipoPessoa from './ng-selector-tipo-pessoa/ng-selector-tipo-pessoa';
import ngSelectorFrontTemplate from './ng-selector-front-template/ng-selector-front-template';
import ngSelectorPixKeys from './ng-selector-pix-keys/ng-selector-pix-keys';

const ngModule = angular
	.module(
		'admin.formly',
		[
			formly,
			formlyBootstrap,

			googleAutocomplete.name,
			googleMapsPosition.name,

			faIcon.name,
			url.name,
			telefone.name,
			integer.name,
			email.name,
			range.name,
			colorPicker.name,
			imageUpload.name,
			radios.name,
			customCheckbox.name,
			reais.name,
			htmlEditor.name,
			simpleList.name,
			ngSelector.name,
			maskPattern.name,
			maskNumber.name,
			data.name,
			dataMMYYYY.name,
			dataDD.name,
			cpf.name,
			cnpj.name,
			cpfcnpj.name,
			celular.name,
			checkboxPlanos.name,

			empresa.name,
			ngSelectorCliente.name,
			ngSelectorPlano.name,
			ngSelectorContrato.name,
			ngSelectorEstado.name,
			ngSelectorEmpresa.name,
			ngSelectorPerfis.name,
			ngSelectorTipoPessoa.name,
			ngSelectorFrontTemplate.name,
			ngSelectorPixKeys.name
		]
	)

	.factory('formlyFactory', function (
		cloudinaryConfig,
		$timeout
	) {

		var palette = [];

		var toLowerCase = function (value) {
			return (value || '').toLowerCase();
		}

		// https://pqina.nl/slim/
		var slimCloudinary = function (attr) {

			var slim = null;
			var initiated = false;
			var didCancel = false;
			var didConfirm = false;
			var currentImage = null;
			var previousImage = null;

			var defaultOptions = {
				instantEdit: false,
				edit: true,
				size: '512,512',
				ratio: "1:1",
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
				didInit: function (obj, element) {
					previousImage = currentImage;
					currentImage = $(element._originalElement).find('img').attr('src');
					initiated = true;
					if (typeof attr.initCallback == 'function') {
						attr.initCallback(currentImage);
					}
				},
				didLoad: function (a, b, c, d, e, f) {
					if (initiated && !didCancel) {
						$timeout(function () {
							previousImage = currentImage;
							currentImage = $(d._originalElement).find('img').attr('src');
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
				didConfirm: function (obj, element) {
					didConfirm = true;
					$timeout(function () {
						previousImage = currentImage;
						currentImage = $(element._originalElement).find('img').attr('src');
					});
					if (typeof attr.didConfirm == 'function') {
						attr.didConfirm();
					}
				},
				didCancel: function () {
					didCancel = true;
					currentImage = previousImage;
					slim.load(previousImage);
					if (typeof attr.cancelCallback == 'function') {
						attr.cancelCallback(previousImage);
					}
				},
				service: function (blobFile, progress, success, failure) {

					if (!didConfirm) { return; }

					// block.start();

					var url = cloudinaryConfig.url;
					var xhr = new XMLHttpRequest();
					var fd = new FormData();

					xhr.open("POST", url, true);
					xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");

					xhr.onreadystatechange = function (e) {
						if (xhr.readyState == 4 && xhr.status == 200) {
							$timeout(function () {
								// block.stop();
								var response = JSON.parse(xhr.responseText);
								attr.uploadedCallback(response.secure_url, response);
							})
						}
					};

					fd.append("upload_preset", attr.uploadPreset);
					fd.append("file", new File(blobFile, blobFile[0].name));

					xhr.send(fd);

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

		var getPalette = function () {
			if (palette.length) {
				return palette;
			}

			palette = ['#d9d9d9', '#bfbfbf', '#a6a6a6', '#8c8c8c', '#737373', '#595959', '#404040', '#262626'];

			var base = ['00', '55', 'aa', 'ff'];

			base.forEach(function (r) {
				base.forEach(function (g) {
					base.forEach(function (b) {
						palette.push('#' + b + g + r);
					})
				})
			})

			return palette;
		}

		return {
			toLowerCase: toLowerCase,
			slimCloudinary: slimCloudinary,
			getPalette: getPalette
		};

	})

	.config(config);

export default ngModule;
