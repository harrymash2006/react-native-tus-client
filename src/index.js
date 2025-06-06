import { NativeModules, NativeEventEmitter } from 'react-native';

const { RNTusClient } = NativeModules;

if (!RNTusClient) {
    console.error('RNTusClient native module is not available');
}

const tusEventEmitter = new NativeEventEmitter(RNTusClient);

const defaultOptions = {
    headers: {},
    metadata: {}
};

// Export native methods directly
export const setupClient = RNTusClient.setupClient;
export const uploadFile = RNTusClient.uploadFile;
export const cancelUpload = RNTusClient.cancelUpload;

// Track active listeners
let activeListeners = 0;

/** Class representing a tus upload */
class Upload {
    /**
     * @param file The file absolute path.
     * @param settings The options argument used to setup your tus upload.
     */
    constructor(file, options) {
        this.file = file;
        this.options = Object.assign({}, defaultOptions, options);
        this.uploadId = null;
        this.subscriptions = [];
        this.isSubscribed = false;
    }

    /**
     * Start or resume the upload using the specified file.
     * If no file property is available the error handler will be called.
     */
    async start() {
        if (!this.file) {
            this.emitError(new Error('tus: no file or stream to upload provided'));
            return;
        }
        if (!this.options.endpoint) {
            this.emitError(new Error('tus: no endpoint provided'));
            return;
        }

        // Subscribe to events before starting the upload
        if (!this.isSubscribed) {
            this.subscribe();
            this.isSubscribed = true;
        }

        try {
            this.uploadId = await RNTusClient.uploadFile(
                this.file,
                this.options.metadata
            );
            console.log('Upload started with ID:', this.uploadId);
        } catch (error) {
            this.emitError(error);
            this.unsubscribe();
            this.isSubscribed = false;
        }
    }

    /**
     * Abort the currently running upload request and don't continue.
     * You can resume the upload by calling the start method again.
     */
    async abort() {
        if (this.uploadId) {
            try {
                await RNTusClient.cancelUpload(this.uploadId);
                this.unsubscribe();
                this.isSubscribed = false;
            } catch (error) {
                this.emitError(error);
            }
        }
    }

    /**
     * Get the current upload progress
     */
    async getProgress() {
        if (!this.uploadId) return 0;
        try {
            return await RNTusClient.getUploadProgress(this.uploadId);
        } catch (error) {
            this.emitError(error);
            return 0;
        }
    }

    emitError(error) {
        if (this.options.onError) {
            this.options.onError(error);
        } else {
            throw error;
        }
    }

    subscribe() {
        console.log('Subscribing to events');
        
        // Subscribe to progress events
        this.subscriptions.push(tusEventEmitter.addListener('uploadProgress', payload => {
            console.log('Progress event received:', payload);
            if (payload.uploadId === this.uploadId) {
                this.onProgress(payload.progress);
            }
        }));
        activeListeners++;

        // Subscribe to completion events
        this.subscriptions.push(tusEventEmitter.addListener('uploadComplete', payload => {
            console.log('Complete event received:', payload);
            if (payload.uploadId === this.uploadId) {
                this.url = payload.uploadUrl;
                this.onSuccess();
                this.unsubscribe();
                this.isSubscribed = false;
            }
        }));
        activeListeners++;

        // Subscribe to error events
        this.subscriptions.push(tusEventEmitter.addListener('uploadError', payload => {
            console.log('Error event received:', payload);
            if (payload.uploadId === this.uploadId) {
                this.onError(payload.error);
                this.unsubscribe();
                this.isSubscribed = false;
            }
        }));
        activeListeners++;
    }

    unsubscribe() {
        console.log('Unsubscribing from events');
        this.subscriptions.forEach(subscription => {
            subscription.remove();
            activeListeners--;
        });
        this.subscriptions = [];
    }

    onSuccess() {
        this.options.onSuccess && this.options.onSuccess();
    }

    onProgress(progress) {
        this.options.onProgress && this.options.onProgress(progress);
    }

    onError(error) {
        this.options.onError && this.options.onError(error);
    }
}

export { Upload };