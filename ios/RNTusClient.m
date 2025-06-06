#import "RNTusClient.h"
#import "RNTusClient-Swift.h"

#define ON_SUCCESS @"onSuccess"
#define ON_ERROR @"onError"
#define ON_PROGRESS @"onProgress"

@interface RNTusClient ()

@property(nonatomic, strong, readonly) NSMutableDictionary<NSString*, TUSSession*> *sessions;
@property(nonatomic, strong, readonly) TUSUploadStore *uploadStore;
@property(nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSString *> *endpoints;

@end

@implementation RNTusClient {
    RNTusClientSwiftBridge *_bridge;
    bool hasListeners;
}

@synthesize uploadStore = _uploadStore;

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessions = [NSMutableDictionary new];
        _endpoints = [NSMutableDictionary new];
        _bridge = [[RNTusClientSwiftBridge alloc] init];
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (TUSUploadStore *)uploadStore {
    if(_uploadStore == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
        _uploadStore = [[TUSFileUploadStore alloc] initWithURL:[applicationSupportURL URLByAppendingPathComponent:@"__uploadStore.tmp"]];
    }
    return _uploadStore;
}

- (TUSSession *)sessionFor:(NSString *)endpoint {
    TUSSession *session = [_sessions objectForKey:endpoint];
    if(session == nil) {
        session = [[TUSSession alloc] initWithEndpoint:[[NSURL alloc] initWithString:endpoint] dataStore:self.uploadStore allowsCellularAccess:YES];
        [self.sessions setObject:session forKey:endpoint];
    }
    return session;
}

- (TUSResumableUpload *)restoreUpload:(NSString *)uploadId {
    NSString *endpoint = self.endpoints[uploadId];
    TUSSession *session = [self sessionFor:endpoint];
    return [session restoreUpload:uploadId];
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"uploadProgress", @"uploadComplete", @"uploadError"];
}

- (void)startObserving {
    hasListeners = YES;
}

- (void)stopObserving {
    hasListeners = NO;
}

RCT_EXPORT_METHOD(uploadFile:(NSString *)filePath
                  uploadURL:(NSString *)uploadURL
                  metadata:(NSDictionary *)metadata
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [_bridge uploadFile:filePath
              uploadURL:uploadURL
              metadata:metadata
              completion:^(NSString *result, NSError *error) {
        if (error) {
            reject(@"upload_error", error.localizedDescription, error);
        } else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(cancelUpload:(NSString *)uploadId)
{
    [_bridge cancelUpload:uploadId];
}

RCT_EXPORT_METHOD(getUploadProgress:(NSString *)uploadId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    double progress = [_bridge getUploadProgress:uploadId];
    resolve(@(progress));
}

@end
