"use strict";

const path = require('path');

const { Storage } = require('@google-cloud/storage');
const storage = new Storage();

class GoogleCloudStorage {
    constructor(bucket, defaultPath) {
        this.bucket = storage.bucket(bucket);
        this.defaultPath = defaultPath || null;
    }

    async write(file, data) {
        if (!file.includes("/")) {
            file = this.defaultPath + "/" + file;
        }

        file = this.bucket.file(file);
        const stream = file.createWriteStream();

        return new Promise((resolve, reject) => {
            stream.on('error', e => {
                console.error(e);

                reject(e);
            });

            stream.on('finish', () => {
                resolve();
            });

            stream.end(data);
        });
    }

    async read(file) {
        if (!file.includes("/")) {
            file = this.defaultPath + "/" + file;
        }

        const fileRef = this.bucket.file(file);
        const stream = fileRef.createReadStream({
            encoding: 'utf8'
        });

        return new Promise((resolve, reject) => {
            const chunks = [];

            stream.on('data', chunk => {
                chunks.push(chunk);
            });

            stream.on('error', e => {
                console.error(e);

                reject(e);
            });

            stream.on('end', () => {
                const data = chunks.join('');

                resolve({
                    filePath: fileRef.name,
                    fileName: path.basename(fileRef.name),
                    content: data
                });
            });
        });
    }

    async getFiles(filePath) {
        const options = {
            prefix: filePath || this.defaultPath
        }

        let [files] = await this.bucket.getFiles(options);

        files = files.map(f => {
            return {
                name: f.name,
                md5Hash: f.metadata.md5Hash
            }
        });

        return files;
    }

    async directoryExists(directoryPrefix) {
        try {
            const options = {
                prefix: directoryPrefix,
                autoPaginate: false,
                maxResults: 1,
            };

            const [files] = await this.bucket.getFiles(options);

            return files.length > 0;
        } catch (e) {
            console.error(e);

            return false;
        }
    }

    responseFile(response, filePath) {
        const fileRef = this.bucket.file(filePath);
        const render = { storageFile: filePath };

        return fileRef.getMetadata()
            .then(getMetadataResponse => {
                render.metadata = getMetadataResponse;
                render.size = getMetadataResponse[0].size;
                render.contentType = getMetadataResponse[0].contentType;

                const metadata = {
                    contentType: render.contentType,
                    cacheControl: 'public, max-age=0',
                    connection: 'keep-alive',
                    contentLength: render.size
                };

                response.setHeader('content-type', metadata.contentType);
                response.setHeader('cache-control', metadata.cacheControl);
                response.setHeader('connection', metadata.connection);
                response.setHeader('content-length', metadata.contentLength);

                return fileRef.createReadStream(
                    { resumable: false, metadata: metadata }
                ).on('error', function (e) {
                    return response.status(500).send(e);
                }).on('finish', function () {
                    return response.end();
                }).pipe(response)

            })

            .catch(e => {
                if (e.code === 404) {
                    render.error = 'not found';

                    return response.status(404).json(render);
                } else {
                    render.error = e;
                    console.error(e);

                    return response.status(500).json(render);
                }
            })

    }

}

module.exports = GoogleCloudStorage;
