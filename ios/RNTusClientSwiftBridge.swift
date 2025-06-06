import Foundation
import TUSKit

@objc public class RNTusClientSwiftBridge: NSObject, TUSClientDelegate {
    private var client: TUSClient?
    private var uploadCallbacks: [UUID: (String?, Error?) -> Void] = [:]
    private var progressCallback: ((String, Float) -> Void)?
    private var completeCallback: ((String, String) -> Void)?
    private var errorCallback: ((String, Error) -> Void)?
    
    @objc public override init() {
        super.init()
    }
    
    @objc public func setProgressCallback(_ callback: @escaping (String, Float) -> Void) {
        progressCallback = callback
    }
    
    @objc public func setCompleteCallback(_ callback: @escaping (String, String) -> Void) {
        completeCallback = callback
    }
    
    @objc public func setErrorCallback(_ callback: @escaping (String, Error) -> Void) {
        errorCallback = callback
    }
    
    @objc public func setupClient(_ serverURL: String, chunkSize: Int = 500 * 1024, error: NSErrorPointer) {
        guard let url = URL(string: serverURL) else {
            error?.pointee = NSError(domain: "RNTusClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])
            return
        }
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.tuskit.upload")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        
        do {
            client = try TUSClient(
                server: url,
                sessionIdentifier: "com.tuskit.upload",
                sessionConfiguration: config,
                chunkSize: chunkSize
            )
            client?.delegate = self
        } catch {
            
        }
    }
    
    @objc public func uploadFile(_ filePath: String, customHeaders: [String: String]? = [:], metadata: [String: String], completion: @escaping (String?, Error?) -> Void) {
        guard let client = client else {
            completion(nil, NSError(domain: "RNTusClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client not initialized"]))
            return
        }
        
        guard let fileURL = URL(string: filePath) else {
            completion(nil, NSError(domain: "file error", code: -2))
            return
        }
        
        var uploadError : Error? = nil
        var uploadId = UUID()
        do {
            uploadId = try client.uploadFileAt(
                filePath: fileURL,
                customHeaders: customHeaders ?? [:],
                context: metadata
            )
            uploadCallbacks[uploadId] = completion
            uploadError = nil
        } catch {
            uploadError = error
        }
        
        if uploadError == nil {
            completion(uploadId.uuidString, nil)
        } else {
            completion(nil, uploadError)
        }
    }
    
    @objc public func cancelUpload(_ uploadId: String) {
        guard let client = client,
              let uuid = UUID(uuidString: uploadId) else { return }
        
        try? client.cancel(id: uuid)
        uploadCallbacks.removeValue(forKey: uuid)
    }
    
    // MARK: - TUSClientDelegate
    
    public func didStartUpload(id: UUID, context: [String: String]?, client: TUSClient) {
        print("Upload started for \(id.uuidString)")
    }
    
    public func didFinishUpload(id: UUID, url: URL, context: [String: String]?, client: TUSClient) {
        if let callback = uploadCallbacks[id] {
            callback(url.absoluteString, nil)
            uploadCallbacks.removeValue(forKey: id)
        }
        completeCallback?(id.uuidString, url.absoluteString)
        print("Finished upload for \(id.uuidString)")
    }
    
    public func uploadFailed(id: UUID, error: Error, context: [String: String]?, client: TUSClient) {
        if let callback = uploadCallbacks[id] {
            callback(nil, error)
            uploadCallbacks.removeValue(forKey: id)
        }
        errorCallback?(id.uuidString, error)
        print("upload failed for \(id.uuidString)")
    }
    
    public func fileError(error: TUSClientError, client: TUSClient) {
        print("file error")
    }
    
    @available(iOS 11.0, *)
    public func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        //print("total progress: \(bytesUploaded)/\(totalBytes)")
    }
    
    @available(iOS 11.0, *)
    public func progressFor(id: UUID, context: [String: String]?, bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
        let progress = Float(bytesUploaded) / Float(totalBytes)
        progressCallback?(id.uuidString, progress)
        //print("progress for \(id.uuidString): \(progress)")
    }
}