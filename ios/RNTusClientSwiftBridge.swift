import Foundation
import TUSKit

@objc class RNTusClientSwiftBridge: NSObject, TUSClientDelegate {
    private var client: TUSClient?
    private var uploadCallbacks: [UUID: (String?, Error?) -> Void] = [:]
    private var progressCallback: ((String, Float) -> Void)?
    private var completeCallback: ((String, String) -> Void)?
    private var errorCallback: ((String, Error) -> Void)?
    
    @objc override init() {
        super.init()
    }
    
    @objc func setProgressCallback(_ callback: @escaping (String, Float) -> Void) {
        progressCallback = callback
    }
    
    @objc func setCompleteCallback(_ callback: @escaping (String, String) -> Void) {
        completeCallback = callback
    }
    
    @objc func setErrorCallback(_ callback: @escaping (String, Error) -> Void) {
        errorCallback = callback
    }
    
    @objc func setupClient(serverURL: String) throws {
        guard let url = URL(string: serverURL) else {
            throw NSError(domain: "RNTusClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
        }
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.tuskit.upload")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        
        client = try TUSClient(
            server: url,
            sessionIdentifier: "com.tuskit.upload",
            sessionConfiguration: config
        )
        client?.delegate = self
    }
    
    @objc func uploadFile(filePath: String, uploadURL: String, metadata: [String: String], completion: @escaping (String?, Error?) -> Void) {
        guard let client = client else {
            completion(nil, NSError(domain: "RNTusClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client not initialized"]))
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let uploadId = UUID()
        
        uploadCallbacks[uploadId] = completion
        
        do {
            try client.uploadFile(at: fileURL, metadata: metadata, context: ["uploadURL": uploadURL])
        } catch {
            completion(nil, error)
            uploadCallbacks.removeValue(forKey: uploadId)
        }
    }
    
    @objc func cancelUpload(uploadId: String) {
        guard let client = client,
              let uuid = UUID(uuidString: uploadId) else { return }
        
        try? client.cancel(id: uuid)
        uploadCallbacks.removeValue(forKey: uuid)
    }
    
    // MARK: - TUSClientDelegate
    
    func didStartUpload(id: UUID, context: [String: String]?, client: TUSClient) {
        // Upload started
    }
    
    func didFinishUpload(id: UUID, url: URL, context: [String: String]?, client: TUSClient) {
        if let callback = uploadCallbacks[id] {
            callback(url.absoluteString, nil)
            uploadCallbacks.removeValue(forKey: id)
        }
        completeCallback?(id.uuidString, url.absoluteString)
    }
    
    func uploadFailed(id: UUID, error: Error, context: [String: String]?, client: TUSClient) {
        if let callback = uploadCallbacks[id] {
            callback(nil, error)
            uploadCallbacks.removeValue(forKey: id)
        }
        errorCallback?(id.uuidString, error)
    }
    
    func fileError(error: TUSClientError, client: TUSClient) {
        // Handle file errors if needed
    }
    
    @available(iOS 11.0, *)
    func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        // Handle total progress if needed
    }
    
    @available(iOS 11.0, *)
    func progressFor(id: UUID, context: [String: String]?, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        let progress = Float(bytesUploaded) / Float(totalBytes)
        progressCallback?(id.uuidString, progress)
    }
} 


