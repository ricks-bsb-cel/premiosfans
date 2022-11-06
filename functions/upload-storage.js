const admin = require('firebase-admin');

const glob = require('glob')
const path = require('path');
const readline = require('readline');
const fs = require('fs');
const moment = require("moment-timezone");

readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);

const serviceAccount = require('./premios-fans-firebase-adminsdk-ga8ql-fed7f24f67.json');

const storagePath = path.join(__dirname, 'storage');
const bucketName = 'premios-fans.appspot.com';

/*
https://cloud.google.com/nodejs/docs/reference/storage/latest
*/

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

const templatePath = 'storage/dev/templates/';

const
    rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

const
    interval = null;

let
    lastResult,
    running = false,
    prodVersionConfig,
    totalUploaded;


console.clear();
console.info("*** upload-storage - Premios Fans Storage Upload ***");
console.info(`Local Storage Path: ${storagePath}`);

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
                case 'r':
                case 'r dev':
                case 'run dev':
                    uploadTemplates('dev');
                    break;
                case 'r prod':
                case 'run prod':
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

    showHelp();
}

const uploadTemplates = env => {
    env = env || 'dev';

    if (running) return;

    running = true;
    prodVersionConfig = getProdVersionConfig();

    let files;

    if (env === 'prod') {
        console.clear();
        console.info(`Uploading to Prod ~ Bucket ${bucketName} ~ Path: ${prodVersionConfig.path}}`);
    }

    getFiles(env)
        .then(getFilesResult => {
            files = getFilesResult;

            return uploadAllFiles(files);
        })
        .then(_ => {
            const templates = [],
                updatePromise = [];

            files
                .filter(f => {
                    return f.source.endsWith('index.html');
                })
                .forEach(f => {
                    const i = templates.findIndex(t => {
                        return t.name === f.template;
                    });

                    if (i < 0) {
                        const t = {
                            nome: f.template,
                            bucket: bucketName,
                            localPath: f.source,
                            storagePathDev: f.destinationDev.replace('/index.html', ''),
                            data: f.data
                        };

                        if (env === 'prod') {
                            t.storagePathProd = f.destinationProd.replace('/index.html', '');
                            t.version = f.idProdVersion;
                        }

                        templates.push(t);
                        updatePromise.push(admin.firestore().collection('frontTemplates').doc(t.nome).set(t, { merge: true }));
                    }
                })

            return Promise.all(updatePromise);
        })
        .then(_ => {
            running = false;
        })
        .catch(e => {
            console.error(e);

            process.exit(0);
        })

}

const uploadAllFiles = f => {
    return new Promise((resolve, reject) => {
        const files = f.slice();

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

    const hoje = moment().tz("America/Sao_Paulo");
    const idProdVersion = hoje.format("YYYY-MM-DD-HH-mm-ss");

    return new Promise((resolve, reject) => {
        const files = glob.sync('storage/**/*.*');

        let result = [];

        files.forEach(f => {
            const d = f.substring(8);
            const s = path.join(storagePath, d);

            const fileStat = fs.statSync(s);

            const file = {
                source: s,
                mtimeMs: fileStat.mtimeMs,
                ctimeMs: fileStat.ctimeMs
            };

            file.destinationDev = `storage/dev/${d}`;
            file.destination = env === 'dev' ? `storage/dev/${d}` : `${prodVersionConfig.path}/${d}`;
            file.upload = env === 'prod' || checkUpload(file);
            file.data = prodVersionConfig.data;

            result.push(file);
        })

        result = result.map(r => {
            if (r.destinationDev.startsWith(templatePath)) {
                r.template = r.destinationDev.substring(templatePath.length).split('/')[0];
            }

            r.destinationProd = r.destinationDev.replace('/dev/', `/prod/${idProdVersion}/`);
            r.idProdVersion = idProdVersion;

            return r;
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

    return lastResult[i].mtimeMs !== file.mtimeMs ||
        lastResult[i].ctimeMs !== file.ctimeMs;
}

const getProdVersionConfig = _ => {
    const hoje = moment().tz("America/Sao_Paulo");
    const id = hoje.format("YYYY-MM-DD-HH-mm-ss");

    return {
        name: 'v ' + hoje.format('YYYY-MM-DD HH-mm-ss'),
        id: id,
        bucket: bucketName,
        path: `storage/prod/${id}`,
        data: hoje.format('DD/MM/YYYY HH:mm:ss')
    };
}

const showHelp = () => {
    console.info();
    console.info('upload-storage CLI Commands');
    console.info('---------------------------');
    console.info('\tr || r dev || run dev: run dev immediately');
    console.info('\trun prod: run prod immediately');
    console.info('\tquit || q: quits ');
    console.info();
}

init();
