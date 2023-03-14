'use strict';

import { initializeApp } from 'firebase/app';

const ngModule = angular.module('services.firebase.config', [])

	/*
	apiKey: "AIzaSyCAWlJXzEptl2TJ8J4CWeBUaA15o-hSqSs",
	authDomain: "premios-fans.firebaseapp.com",
	databaseURL: "https://premios-fans-default-rtdb.firebaseio.com",
	projectId: "premios-fans",
	storageBucket: "premios-fans.appspot.com",
	messagingSenderId: "801994869227",
	appId: "1:801994869227:web:188d640a390d22aa4831ae",
	measurementId: "G-XTRQ740MSL"
	*/

	.constant('firebaseConfigBase64', 'eyJhcGlLZXkiOiAiQUl6YVN5Q0FXbEpYekVwdGwyVEo4SjRDV2VCVWFBMTVvLWhTcVNzIiwiYXV0aERvbWFpbiI6InByZW1pb3MtZmFucy5maXJlYmFzZWFwcC5jb20iLCJkYXRhYmFzZVVSTCI6Imh0dHBzOi8vcHJlbWlvcy1mYW5zLWRlZmF1bHQtcnRkYi5maXJlYmFzZWlvLmNvbSIsInByb2plY3RJZCI6InByZW1pb3MtZmFucyIsInN0b3JhZ2VCdWNrZXQiOiJwcmVtaW9zLWZhbnMuYXBwc3BvdC5jb20iLCJtZXNzYWdpbmdTZW5kZXJJZCI6ICI4MDE5OTQ4NjkyMjciLCJhcHBJZCI6IjE6ODAxOTk0ODY5MjI3OndlYjoxODhkNjQwYTM5MGQyMmFhNDgzMWFlIiwibWVhc3VyZW1lbnRJZCI6IkctWFRSUTc0ME1TTCJ9')

	.constant('firebaseErrorCodes',
		[
			{ "error": "auth/claims-too-large", "detalhes": "O payload de declarações fornecido para setCustomUserClaims() excede o tamanho máximo permitido de 1000 bytes.", "mensagem": "" },
			{ "error": "auth/invalid-argument", "detalhes": "Um argumento inválido foi fornecido a um método do Authentication. A mensagem de erro precisa conter informações adicionais.", "mensagem": "" },
			{ "error": "auth/invalid-claims", "detalhes": "Os atributos de declaração personalizados fornecidos para setCustomUserClaims() são inválidos.", "mensagem": "" },
			{ "error": "auth/invalid-disabled-field", "detalhes": "O valor fornecido para a propriedade de usuário disabled é inválido. Precisa ser um valor booleano.", "mensagem": "" },
			{ "error": "auth/invalid-display-name", "detalhes": "O valor fornecido para a propriedade de usuário displayName é inválido. Precisa ser uma string não vazia.", "mensagem": "" },
			{ "error": "auth/invalid-email-verified", "detalhes": "O valor fornecido para a propriedade de usuário emailVerified é inválido. Precisa ser um valor booleano.", "mensagem": "" },
			{ "error": "auth/invalid-email", "detalhes": "O valor fornecido para a propriedade de usuário email é inválido. Precisa ser um endereço de e-mail de string.", "mensagem": "O e-mail informado é invalido." },
			{ "error": "auth/invalid-page-token", "detalhes": "O token fornecido de próxima página em listUsers() é inválido. Precisa ser uma string não vazia válida.", "mensagem": "" },
			{ "error": "auth/invalid-password", "detalhes": "O valor fornecido para a propriedade de usuário password é inválido. Precisa ser uma string com pelo menos seis caracteres.", "mensagem": "" },
			{ "error": "auth/invalid-phone-number", "detalhes": "O valor fornecido para o phoneNumber é inválido. Ele precisa ser uma string de identificador compatível com o padrão E.164 não vazio.", "mensagem": "" },
			{ "error": "auth/invalid-photo-url", "detalhes": "O valor fornecido para a propriedade de usuário photoURL é inválido. Precisa ser um URL de string.", "mensagem": "" },
			{ "error": "auth/invalid-uid", "detalhes": "O uid fornecido precisa ser uma string não vazia com no máximo 128 caracteres.", "mensagem": "" },
			{ "error": "auth/missing-uid", "detalhes": "Um identificador uid é necessário para a operação atual.", "mensagem": "" },
			{ "error": "auth/reserved-claims", "detalhes": "Uma ou mais declarações de usuário personalizadas fornecidas para setCustomUserClaims() são reservadas. Por exemplo, não use as declarações específicas do OIDC, como (sub, iat, iss, exp, aud, auth_time etc.) como chaves para declarações personalizadas.", "mensagem": "" },
			{ "error": "auth/uid-alread-exists", "detalhes": "O uid fornecido já está em uso por um usuário existente. Cada usuário precisa ter um uid exclusivo.", "mensagem": "" },
			{ "error": "auth/email-already-exists", "detalhes": "O e-mail fornecido já está em uso por outro usuário. Cada usuário precisa ter um e-mail exclusivo.", "mensagem": "" },
			{ "error": "auth/user-not-found", "detalhes": "Não há registro de usuário existente correspondente ao identificador fornecido.", "mensagem": "Não existe nenhum usuário com o e-mail informado." },
			{ "error": "auth/operation-not-allowed", "detalhes": "O provedor de login fornecido está desativado para o projeto do Firebase. Ative-o na seção Método de login no Firebase console.", "mensagem": "" },
			{ "error": "auth/invalid-credential", "detalhes": "A credencial usada para autenticar os SDKs Admin não pode ser usada para executar a ação desejada. Determinados métodos do Authentication, como createCustomToken() e verifyIdToken(), exigem que o SDK seja inicializado com uma credencial de certificado, e não com um token de atualização ou credencial padrão do aplicativo. Consulte Inicializar o SDK para ver a documentação sobre como autenticar os Admin SDKs com uma credencial de certificado.", "mensagem": "" },
			{ "error": "auth/phone-number-already-exists", "detalhes": "O phoneNumber fornecido já está em uso por um usuário existente. Cada usuário precisa ter um phoneNumber exclusivo.", "mensagem": "" },
			{ "error": "auth/project-not-found", "detalhes": "Nenhum projeto do Firebase foi encontrado com a credencial usada para inicializar os Admin SDKs. Consulte Adicionar o Firebase ao seu app para ver a documentação sobre como gerar uma credencial para o seu projeto e usá-la para autenticar os Admin SDKs.", "mensagem": "" },
			{ "error": "auth/insufficient-permission", "detalhes": "A credencial usada para inicializar o Admin SDK não tem permissão para acessar o recurso solicitado do Authentication. Consulte Adicionar o Firebase ao seu app para ver a documentação sobre como gerar uma credencial com permissões adequadas e usá-la para autenticar os Admin SDKs.", "mensagem": "" },
			{ "error": "auth/internal-error", "detalhes": "O servidor do Authentication encontrou um erro inesperado ao tentar processar a solicitação. A mensagem de erro precisa conter a resposta do servidor do Authentication com informações adicionais. Se o erro persistir, informe o problema ao nosso canal de suporte de Relatório do bug.", "mensagem": "" },
			{ "error": "auth/weak-password", "detalhes": "A senha informada é muito fraca.", "mensagem": "A senha informada é muito fraca. Verifique sua senha e informe uma senha mais apropriada." },
			{ "error": "auth/wrong-password", "detalhes": "Usuário e/ou senha inválidos. Verifique seus dados e tente novamente.", "mensagem": "Usuário e/ou senha inválidos.<br />Verifique seus dados e tente novamente." },
			{ "error": "auth/email-already-in-use", "detalhes": "Já existe um usuário com o e-mail informado. Caso tenha esquecido sua senha utilize a rotina de recuperação.", "mensagem": "Já existe um usuário com o e-mail informado. Caso tenha esquecido sua senha utilize a rotina de recuperação." },
			{ "error": "auth/popup-closed-by-user", "detalhes": "A janela de login foi fechada antes da autenticação do acesso.", "mensagem": "A janela de login foi fechada antes da autenticação do acesso." },
			{ "error": "permission-denied", "detalhes": "Permissão negada" }
		]
	)

	.value('firebaseAuthMessages', {
		'auth/email-already-in-use': 'Já existe uma conta com este e-mail no sistema. Se necessário, utilize a rotina de recuperação de senha.',
		'auth/invalid-email': 'O endereço de e-mail informado é inválido',
		'auth/operation-not-allowed': 'O acesso com e-mail e senha foi desabilitado',
		'auth/weak-password': 'A nova senha informada é muito fraca. Escolha uma senha mais forte...',
		'auth/missing-android-pkg-name': 'An Android package name must be provided if the Android app is required to be installed.',
		'auth/missing-continue-uri': 'A continue URL must be provided in the request.',
		'auth/missing-ios-bundle-id': 'An iOS bundle ID must be provided if an App Store ID is provided.',
		'auth/invalid-continue-uri': 'The continue URL provided in the request is invalid.',
		'auth/unauthorized-continue-uri': 'The domain of the continue URL is not whitelisted. Whitelist the domain in the Firebase console.',
		'auth/user-disabled': 'Desculpe, mas seu email foi bloqueado na nossa plataforma.',
		'auth/user-not-found': 'Usuário não encontrado.',
		'auth/wrong-password': 'Senha inválida.',
		'auth/too-many-requests': 'Tente novamente mais tarde...',
		'auth/expired-action-code': 'Desculpe, mas o processo solicitado expirou.',
		'auth/invalid-action-code': 'O processo de alteração de senha expirou, já foi utilizado ou é inválido.',
		'auth/missing-android-pkg-name': 'An Android package name must be provided if the Android app is required to be installed.',
		'auth/missing-ios-bundle-id': 'An iOS Bundle ID must be provided if an App Store ID is provided.',
		'auth/invalid-continue-uri': 'The continue URL provided in the request is invalid.',
		'auth/unauthorized-continue-uri': 'The domain of the continue URL is not whitelisted. Whitelist the domain in the Firebase console.',
		'auth/invalid-verification-code': 'O código informado é inválido.',
		'auth/missing-verification-code': 'Informe o código para validação do seu celular',
		'auth/code-expired': 'O código informado está expirado. Você deve solicitar outro...'
	})

	.run(
		function (
			firebaseConfigBase64,
			appService
		) {
			const jsonfirebaseConfig = Buffer.from(firebaseConfigBase64, 'base64').toString();
			const firebaseConfig = JSON.parse(jsonfirebaseConfig);
			const app = initializeApp(firebaseConfig);

			appService.init(app);
		}
	);

export default ngModule;
