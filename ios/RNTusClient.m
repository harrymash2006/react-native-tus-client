#import "RNTusClient.h"
#import "RNTusClient-Swift.h"

@implementation RNTusClient {
    RNTusClientSwiftBridge *_bridge;
    bool hasListeners;
}

RCT_EXPORT_MODULE();

- (instancetype)init {
    self = [super init];
    if (self) {
        _bridge = [[RNTusClientSwiftBridge alloc] init];
        [_bridge setProgressCallback:^(NSString *uploadId, float progress) {
            if (self->hasListeners) {
                [self sendEventWithName:@"uploadProgress" body:@{
                    @"uploadId": uploadId,
                    @"progress": @(progress)
                }];
            }
        }];
        
        [_bridge setStartCallback:^(NSString *uploadId) {
            if (self->hasListeners) {
                [self sendEventWithName:@"uploadStarted" body:@{
                    @"uploadId": uploadId
                }];
            }
        }];
        
        [_bridge setCompleteCallback:^(NSString *uploadId, NSString *uploadUrl) {
            if (self->hasListeners) {
                [self sendEventWithName:@"uploadComplete" body:@{
                    @"uploadId": uploadId,
                    @"uploadUrl": uploadUrl
                }];
            }
        }];
        
        [_bridge setErrorCallback:^(NSString *uploadId, NSError *error) {
            if (self->hasListeners) {
                [self sendEventWithName:@"uploadError" body:@{
                    @"uploadId": uploadId,
                    @"error": error.localizedDescription ?: @"Unknown error"
                }];
            }
        }];
    }
    return self;
}

- (void)registerBackgroundHandler:(void (^)(void))completionHandler {
    [_bridge registerBackgroundHandler:completionHandler];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"uploadStarted", @"uploadProgress", @"uploadComplete", @"uploadError"];
}

- (void)startObserving {
    hasListeners = YES;
}

- (void)stopObserving {
    hasListeners = NO;
}

RCT_EXPORT_METHOD(setupClient:(NSString *)serverURL
                  chunkSize: (NSNumber *)chunkSize
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSError *error;
    [_bridge setupClient:serverURL chunkSize:[chunkSize intValue]  error:&error];
    
    if (error) {
        reject(@"setup_error", error.localizedDescription, error);
    } else {
        resolve(nil);
    }
}

RCT_EXPORT_METHOD(uploadFile:(NSString *)filePath
                  customHeaders: (NSDictionary *)customHeaders
                  metadata:(NSDictionary *)metadata
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [_bridge uploadFile:filePath customHeaders: customHeaders metadata:metadata completion:^(NSString *uploadId, NSError *error) {
        if (error) {
            reject(@"upload_error", error.localizedDescription, error);
        } else {
            resolve(uploadId);
        }
    }];
}

RCT_EXPORT_METHOD(cancelUpload:(NSString *)uploadId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [_bridge cancelUpload:uploadId];
    resolve(nil);
}

@end
