#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNTusClient : RCTEventEmitter <RCTBridgeModule>

- (void)registerBackgroundHandler:(void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
  
