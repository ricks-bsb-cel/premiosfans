
import factoryGlobal from './global';
import factoryAlert from './alert';
import factoryToastr from './toastr';
import factoryBlockUi from './block-ui';
import factoryWaitUi from './wait-ui';

import factoryRecoveryPassword from './recovery-password/recovery-password';
import factoryNewPassword from './new-password/new-password';

const ngModule = angular.module(
	'factories',
	[
		factoryGlobal.name,
		factoryAlert.name,
		factoryToastr.name,
		factoryBlockUi.name,
		factoryRecoveryPassword.name,
		factoryNewPassword.name,
		factoryWaitUi.name
	]
);

export default ngModule;
