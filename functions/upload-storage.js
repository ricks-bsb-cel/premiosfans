const { Storage } = require('@google-cloud/storage');
const initFirebase = require("./initFirebase");
const glob = require('glob')
const path = require('path');

const parms = {
    env: process.env.npm_config_env
};

const storagePath = path.join(__dirname, 'storage');
const storage = new Storage();
const bucketName = 'premios-fans.appspot.com';

console.clear();
console.info("*** upload-storage - Premios Fans Storage Upload ***");
console.info(`Local Storage Path: ${storagePath}`);
console.info();

if (!parms.env || !("prod,desenv").includes(parms.env)) {
    console.info(("use: npm run upload-storage --env=desenv|prod"))
    process.exit(0);
}

const uploadTemplates = _ => {
    getFiles()
        .then(files => {
            console.info(`Uploading. Environment: ${parms.env}`);
            console.info();
            return uploadAllFiles(files);
        })
        .then(_ => {
            console.info();
            console.info('Finished');

            process.exit(0);
        })
        .catch(e => {
            console.error(e);

            process.exit(0);
        })

}

const uploadAllFiles = files => {
    return new Promise((resolve, reject) => {

        const uploadNextFile = _ => {

            if (!files.length) {
                return resolve();
            }

            const nextFile = files.shift();

            const options = {
                destination: nextFile.destination
            };

            console.info(`Uploading ${nextFile.destination}`);

            storage.bucket(bucketName).upload(nextFile.source, options)
                .then(_ => {
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

const getFiles = _ => {
    return new Promise((resolve, reject) => {
        glob('storage/**/*.*', (e, files) => {
            if (e) {
                console.error(e);
                return reject(new Error(`Erro carregando arquivos...`));
            } else {

                let result = [];

                files.forEach(f => {
                    const d = f.substring(8);
                    result.push({
                        source: path.join(storagePath, d),
                        destination: `storage/${parms.env}/${d}`
                    })
                })

                return resolve(result);
            }
        })
    })
}

initFirebase.call(uploadTemplates);
