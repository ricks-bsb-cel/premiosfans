var pwaName = "PF Partners";
var pwaRemind = 1;       // Days to re-remind to add to home
var pwaNoCache = false;  // Requires server and HTTPS/SSL. Will clear cache with each visit

var pwaScope = "/app/";
var pwaLocation = "/app/_service-worker.js";

let isMobile = {
    Android: function() {return navigator.userAgent.match(/Android/i);},
    iOS: function() {return navigator.userAgent.match(/iPhone|iPad|iPod/i);},
    any: function() {return (isMobile.Android() || isMobile.iOS());}
};

document.addEventListener('DOMContentLoaded', () => {

    var iOS_PWA = document.querySelectorAll('#menu-install-pwa-ios')[0];
    if (iOS_PWA) { var iOS_Window = new bootstrap.Offcanvas(iOS_PWA) }
    var Android_PWA = document.querySelectorAll('#menu-install-pwa-android')[0];
    if (Android_PWA) { var Android_Window = new bootstrap.Offcanvas(Android_PWA) }

    var checkPWA = document.getElementsByTagName('html')[0];

    if (!checkPWA.classList.contains('isPWA')) {

        if ('serviceWorker' in navigator) {
            window.addEventListener('load', function () {
                navigator.serviceWorker.register(pwaLocation, { scope: pwaScope })
                    .then(registration => {
                        registration.update();
                    })
                    .catch(e => {
                        console.error(e);
                    })
            });
        }

        //Setting Timeout Before Prompt Shows Again if Dismissed
        var hours = pwaRemind * 24; // Reset when storage is more than 24hours
        var now = Date.now();
        var setupTime = localStorage.getItem(pwaName + '-PWA-Timeout-Value');

        if (setupTime == null) {
            localStorage.setItem(pwaName + '-PWA-Timeout-Value', now);
        } else if (now - setupTime > hours * 60 * 60 * 1000) {
            localStorage.removeItem(pwaName + '-PWA-Prompt')
            localStorage.setItem(pwaName + '-PWA-Timeout-Value', now);
        }


        const pwaClose = document.querySelectorAll('.pwa-dismiss');

        pwaClose.forEach(el => el.addEventListener('click', e => {
            const pwaWindows = document.querySelectorAll('#menu-install-pwa-android, #menu-install-pwa-ios');
            for (let i = 0; i < pwaWindows.length; i++) { pwaWindows[i].classList.remove('menu-active'); }
            localStorage.setItem(pwaName + '-PWA-Timeout-Value', now);
            localStorage.setItem(pwaName + '-PWA-Prompt', 'install-rejected');
            console.log('PWA Install Rejected. Will Show Again in ' + (pwaRemind) + ' Days')
        }));

        //Trigger Install Prompt for Android
        const pwaWindows = document.querySelectorAll('#menu-install-pwa-android, #menu-install-pwa-ios');
        
        if (pwaWindows.length) {
            if (isMobile.Android()) {
                if (localStorage.getItem(pwaName + '-PWA-Prompt') != "install-rejected") {
                    function showInstallPrompt() {
                        setTimeout(function () {
                            if (!window.matchMedia('(display-mode: fullscreen)').matches) {
                                console.log('Triggering PWA Window for Android')
                                Android_Window.show()
                            }
                        }, 3500);
                    }
                    var deferredPrompt;
                    window.addEventListener('beforeinstallprompt', (e) => {
                        e.preventDefault();
                        deferredPrompt = e;
                        showInstallPrompt();
                    });
                }
                const pwaInstall = document.querySelectorAll('.pwa-install');
                pwaInstall.forEach(el => el.addEventListener('click', e => {
                    deferredPrompt.prompt();
                    deferredPrompt.userChoice
                        .then((choiceResult) => {
                            if (choiceResult.outcome === 'accepted') {
                                console.log('Added');
                            } else {
                                localStorage.setItem(pwaName + '-PWA-Timeout-Value', now);
                                localStorage.setItem(pwaName + '-PWA-Prompt', 'install-rejected');
                                setTimeout(function () {
                                    if (!window.matchMedia('(display-mode: fullscreen)').matches) {
                                        Android_Window.show()
                                    }
                                }, 50);
                            }
                            deferredPrompt = null;
                        });
                }));
                window.addEventListener('appinstalled', (evt) => {
                    Android_Window.hide()
                });
            }
            //Trigger Install Guide iOS
            if (isMobile.iOS()) {
                if (localStorage.getItem(pwaName + '-PWA-Prompt') != "install-rejected") {
                    setTimeout(function () {
                        if (!window.matchMedia('(display-mode: fullscreen)').matches) {
                            console.log('Triggering PWA Window for iOS');
                            iOS_Window.show()
                        }
                    }, 3500);
                }
            }
        }
    }
   
    checkPWA.setAttribute('class', 'isPWA');

});