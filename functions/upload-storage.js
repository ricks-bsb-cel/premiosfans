const admin = require('firebase-admin');

const glob = require('glob')
const path = require('path');
const readline = require('readline');
const fs = require('fs');
const crypto = require('crypto');
const moment = require("moment-timezone");

readline.emitKeypressEvents(process.stdin);
process.stdin.setRawMode(true);

const serviceAccount = require('./premios-fans-firebase-adminsdk-ga8ql-fed7f24f67.json');

const storagePath = path.join(__dirname, 'storage');
const bucketName = 'premios-fans-templates';

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

const storage = admin.storage();
const localTemplatePath = 'storage';
let interval = null;

const
    rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

function endExecution(code) {
    process.exit(code || 0);
}

function getLocalFileMd5Hash(file) {
    const fileData = fs.readFileSync(file);
    return crypto.createHash('md5').update(fileData).digest('base64');
}

async function getStorageFiles() {
    const [files] = await storage.bucket(bucketName).getFiles();

    const result = files.map(f => {
        return {
            name: f.name,
            md5Hash: f.metadata.md5Hash
        }
    })

    return result;
}

async function getLocalFiles() {
    const files = await glob.sync(`${localTemplatePath}/**/*.*`);
    const result = [];

    files.forEach(f => {
        result.push({
            name: f,
            md5Hash: getLocalFileMd5Hash(f),
            changed: false
        })
    })

    return result;
}

async function uploadToStorage(localFiles) {
    console.info('Uploading...');

    for (const f of localFiles) {
        const fileName = path.basename(f.name);
        const fileDir = path.dirname(f.name);

        // Faz upload do arquivo para o Google Cloud Storage
        const [file] = await storage.bucket(bucketName).upload(f.name, {
            destination: `${fileDir}/${fileName}`,
        });

        console.log(`Arquivo ${f.name} enviado para o bucket ${bucketName} [${file.metadata.md5Hash}], ${file.metadata.size} bytes`);
        
        rl.prompt();
    }
}

console.clear();
console.info("*** upload-storage - Storage Upload ***");
console.info(`Local Storage Path: ${localTemplatePath}`);

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
                case 'run':
                    uploadData();
                    break;
                case 's':
                case 'start':
                    startInterval(10);
                    break;
                case 'e':
                case 'end':
                    stopInterval();
                    break;
                default:
                    showHelp();

            }

            rl.prompt();
        })

        .on('close', function () {
            console.log('😎 Have a nice day!');
            endExecution();
        });

    showHelp();
}

async function uploadData() {
    try {

        const filesOnStorage = await getStorageFiles();
        let localFiles = await getLocalFiles();

        // Remove da lista de arquivos locais os arquivos que tem o mesmo md5Hash (pois não foram alterados) ou que não existem no storage
        localFiles = localFiles.map(localFile => {
            const i = filesOnStorage.findIndex(storageFile => storageFile.name === localFile.name);

            localFile.changed = (i < 0 || (i >= 0 && localFile.md5Hash !== filesOnStorage[i].md5Hash));

            return localFile;
        }).filter(f => f.changed);

        /*
        if (localFiles.length) {
            console.info('local files');
            console.table(localFiles);
        }else{
            console.info('No files to update');
        }

        if (filesOnStorage.length) {
            console.info('on storage');
            console.table(filesOnStorage);
        }
        */

        if (localFiles.length) {
            console.info();
            await uploadToStorage(localFiles);
        }
    }
    catch (e) {
        console.error(e);
        endExecution();
    }
}

function startInterval(i) {
    interval = setInterval(uploadData, i * 1000);
    console.info('Interval start...');
}

function stopInterval() {
    if (interval) {
        clearInterval(interval);
        console.info('Interval end...');
    }
}


const showHelp = () => {
    console.info();
    console.info('upload-storage CLI Commands');
    console.info('---------------------------');
    console.info('\tr || run: just run immediately');
    console.info('\tstart || s: Start Interval  (10 seconds)');
    console.info('\tend || e: End Interval ');
    console.info('\tquit || q: quits ');
    console.info();
}

init();
