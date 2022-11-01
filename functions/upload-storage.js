const admin = require("firebase-admin");

const glob = require('glob')
const path = require('path');
const readline = require('readline');
const fs = require('fs');
const moment = require("moment-timezone");

readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);

const serviceAccount = require("./premios-fans-firebase-adminsdk-ga8ql-fed7f24f67.json");

const storagePath = path.join(__dirname, 'storage');
const bucketName = 'premios-fans.appspot.com';

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),

    apiKey: "AIzaSyCAWlJXzEptl2TJ8J4CWeBUaA15o-hSqSs",
    authDomain: "premios-fans.firebaseapp.com",
    databaseURL: "https://premios-fans-default-rtdb.firebaseio.com",
    projectId: "premios-fans",
    storageBucket: "premios-fans.appspot.com",
    messagingSenderId: "801994869227",
    appId: "1:801994869227:web:188d640a390d22aa4831ae",
    measurementId: "G-XTRQ740MSL"
});

let
    lastResult,
    tInterval = 5000,
    interval = null,
    lineTyping = null,
    running = false,
    prodVersionConfig,
    totalUploaded,
    rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

console.clear();
console.info("*** upload-storage - Premios Fans Storage Upload ***");
console.info(`Local Storage Path: ${storagePath}`);
console.info();

const init = _ => {

    rl.setPrompt('▪ upload-storage> ');

    rl
        .on('line', function (command) {
            command = command.trim().toLowerCase();

            switch (command) {
                case 'quit':
                case 'q':
                    rl.close();
                    break;
                case 'run dev':
                case 'r dev':
                    uploadTemplates('dev');
                    break;
                case 'run prod':
                case 'r prod':
                    uploadTemplates('prod');
                    break;
                default:
                    showHelp();

            }

            rl.prompt();
        })

        .on('close', function () {
            interval && clearInterval(interval);
            console.log('😎 Have a nice day!');
            process.exit(0);
        });

    initInterval();
}

const uploadTemplates = env => {
    env = env || 'dev';

    if (running) return;

    running = true;
    prodVersionConfig = getProdVersionConfig();

    if (env === 'prod') {
        console.clear();
        console.info(`Uploading to Prod ~ Bucket ${bucketName} ~ Path: ${prodVersionConfig.path}}`);
    }

    getFiles(env)
        .then(files => {
            running = false;
            return uploadAllFiles(files);
        })
        .then(_ => {
            if (env === 'dev') {
                return null;
            } else {
                return admin.database().ref(`storageConfig/${prodVersionConfig.id}`).set({
                    ...prodVersionConfig,
                    totalFiles: totalUploaded
                });
            }
        })
        .catch(e => {
            console.error(e);

            process.exit(0);
        })

}

const uploadAllFiles = files => {
    return new Promise((resolve, reject) => {

        totalUploaded = 0;

        const uploadNextFile = _ => {

            if (!files.length) {
                if (totalUploaded) {
                    console.info(`${totalUploaded} file(s) uploaded`);
                    console.info();
                }

                return resolve();
            }

            const nextFile = files.shift();

            if (!nextFile.upload) {
                uploadNextFile();
                return;
            }

            const options = {
                destination: nextFile.destination
            };

            console.info(`Uploading ${nextFile.destination}`);

            admin.storage().bucket(bucketName).upload(nextFile.source, options)
                .then(_ => {
                    totalUploaded++;

                    uploadNextFile();
                })
                .catch(e => {
                    console.error(e);
                    return reject(e);
                })

        }

        uploadNextFile();

    })
}

const getFiles = env => {
    env = env || 'dev';

    return new Promise((resolve, reject) => {
        const files = glob.sync('storage/**/*.*');

        let result = [];

        files.forEach(f => {
            const d = f.substring(8);
            const s = path.join(storagePath, d);

            const fileStat = fs.statSync(s);

            let file = {
                source: s,
                mtimeMs: fileStat.mtimeMs,
                ctimeMs: fileStat.ctimeMs
            };

            file.destination = env === 'dev' ? `storage/dev/${d}` : `${prodVersionConfig.path}/${d}`;
            file.upload = env === 'prod' || checkUpload(file);

            result.push(file);
        })

        lastResult = result.slice();

        return resolve(result);
    })
}

const checkUpload = file => {
    if (!lastResult || lastResult.length === 0) {
        return true;
    }

    const i = lastResult.findIndex(f => {
        return f.source === file.source;
    })

    // Se não encontrado, upload...
    if (i < 0) return true;

    return lastResult[i].mtimeMs !== file.mtimeMs || lastResult[i].ctimeMs !== file.ctimeMs;
}

const initInterval = _ => {
    var pauseTimer = null;

    interval = setInterval(function () {
        if (lineTyping != rl.line) {
            lineTyping = rl.line;

            if (interval) { clearInterval(interval); }
            if (pauseTimer) { clearTimeout(pauseTimer); }

            pauseTimer = setTimeout(function () {
                initInterval();
            }, 5000);

        } else {
            uploadTemplates('dev');
        }
    }, tInterval);
}

const getProdVersionConfig = _ => {
    const hoje = moment().tz("America/Sao_Paulo");
    const id = hoje.format("YYYY-MM-DD-HH-mm-ss");

    return {
        name: 'v ' + hoje.format("YYYY-MM-DD HH-mm-ss"),
        id: id,
        bucket: bucketName,
        path: `storage/prod/${id}`
    };
}

const showHelp = () => {
    console.info();
    console.info('upload-storage CLI Commands');
    console.info('------------------------');
    console.info('\trun dev || r: run dev immediately');
    console.info('\trun prod || r: run prod immediately');
    console.info('\tquit || q: quits ');
    console.info();
}

init();
