
import factoryGlobal from './global';
import factoryAlert from './alert';
import factoryToastr from './toastr';
import factoryBlockUi from './block-ui';
import factoryImages from './images';
import factoryPexels from './pexels';
import factoryCollections from './collections';

import factoryNewUser from './new-user/new-user';
import factoryRecoveryPassword from './recovery-password/recovery-password';
import factoryNewPassword from './new-password/new-password';
import factoryImageChooser from './image-chooser/image-chooser';

import factoryEntidades from './entidades';

const ngModule = angular.module(
	'factories',
	[
		factoryGlobal.name,
		factoryAlert.name,
		factoryToastr.name,
		factoryBlockUi.name,
		factoryImages.name,
		factoryPexels.name,
		factoryNewUser.name,
		factoryRecoveryPassword.name,
		factoryNewPassword.name,
		factoryImageChooser.name,
		factoryCollections.name,
		factoryEntidades.name
	]
);

export default ngModule;
