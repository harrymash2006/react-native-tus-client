import Foundation
import TUSKit

@objc class RNTusClientSwiftBridge: NSObject {
    private let client: TUSClient
    private var uploads: [String: TUSUpload] = [:]
    
    @objc override init() {
        // Initialize TUSClient with default configuration
        self.client = TUSClient.shared
        super.init()
    }
    
    @objc func uploadFile(filePath: String, uploadURL: String, metadata: [String: String], completion: @escaping (String?, Error?) -> Void) {
        let fileURL = URL(fileURLWithPath: filePath)
        
        // Create upload
        let upload = TUSUpload(fileURL: fileURL, uploadURL: URL(string: uploadURL)!, metadata: metadata)
        
        // Store upload reference
        let uploadId = UUID().uuidString
        uploads[uploadId] = upload
        
        // Start upload
        client.upload(upload) { [weak self] result in
            switch result {
            case .success(let uploadURL):
                self?.uploads.removeValue(forKey: uploadId)
                completion(uploadURL.absoluteString, nil)
            case .failure(let error):
                self?.uploads.removeValue(forKey: uploadId)
                completion(nil, error)
            }
        }
    }
    
    @objc func cancelUpload(uploadId: String) {
        if let upload = uploads[uploadId] {
            client.cancel(upload)
            uploads.removeValue(forKey: uploadId)
        }
    }
    
    @objc func getUploadProgress(uploadId: String) -> Double {
        if let upload = uploads[uploadId] {
            return upload.progress
        }
        return 0.0
    }
} 
