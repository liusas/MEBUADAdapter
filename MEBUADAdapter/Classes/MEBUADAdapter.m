//
//  MEBUADAdapter.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/25.
//

#import "MEBUADAdapter.h"
#import <BUAdSDK/BUAdSDKManager.h>

// Initialization configuration keys
static NSString * const kBUADAppID = @"appid";

// Errors
static NSString * const kAdapterErrorDomain = @"com.mobipub.mobipub-ios-sdk.mobipub-buad-adapter";

typedef NS_ENUM(NSInteger, BUADAdapterErrorCode) {
    BUADAdapterErrorCodeMissingAppId,
};

@implementation MEBUADAdapter

#pragma mark - Caching

+ (void)updateInitializationParameters:(NSDictionary *)parameters {
    // These should correspond to the required parameters checked in
    // `initializeNetworkWithConfiguration:complete:`
    NSString * appId = parameters[kBUADAppID];
    
    if (appId != nil) {
        NSDictionary * configuration = @{ kBUADAppID: appId };
        [MEBUADAdapter setCachedInitializationParameters:configuration];
    }
}

#pragma mark - MPAdapterConfiguration

- (NSString *)adapterVersion {
    return @"1.0.12";
}

- (NSString *)biddingToken {
    return nil;
}

- (NSString *)mobiNetworkName {
    return @"tt";
}

- (NSString *)networkSdkVersion {
    return @"3.2.6.2";
}

#pragma mark - MobiPub ad type
- (Class)getSplashCustomEvent {
    return NSClassFromString(@"MobiBUADSplashCustomEvent");
}

- (Class)getBannerCustomEvent {
    return NSClassFromString(@"MobiBUADBannerCustomEvent");
}

- (Class)getFeedCustomEvent {
    return NSClassFromString(@"MobiBUADFeedCustomEvent");
}

- (Class)getInterstitialCustomEvent {
    return NSClassFromString(@"MobiBUADInterstitialCustomEvent");
}

- (Class)getRewardedVideoCustomEvent {
    return NSClassFromString(@"MobiBUADRewardedVideoCustomEvent");
}

- (Class)getFullscreenCustomEvent {
    return NSClassFromString(@"MobiBUADFullscreenCustomEvent");
}

- (Class)getDrawViewCustomEvent {
    return NSClassFromString(@"MobiBUADDrawViewCustomEvent");
}

- (void)initializeNetworkWithConfiguration:(NSDictionary<NSString *,id> *)configuration complete:(void (^)(NSError * _Nullable))complete {

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appid = configuration[kBUADAppID];
//        [BUAdSDKManager setAppID:@"5000546"];
        [BUAdSDKManager setAppID:appid];
#if DEBUG
        // Whether to open log. default is none.
        [BUAdSDKManager setLoglevel:BUAdSDKLogLevelDebug];
#endif
        [BUAdSDKManager setIsPaidApp:NO];
        
        if (complete != nil) {
            complete(nil);
        }
    });
}

// MoPub collects GDPR consent on behalf of Google
+ (NSString *)npaString
{
//    return !MobiPub.sharedInstance.canCollectPersonalInfo ? @"1" : @"";
    return @"";
}

/// 获取顶层VC
+ (UIViewController *)topVC {
    UIWindow *rootWindow = [UIApplication sharedApplication].keyWindow;
    if (![[UIApplication sharedApplication].windows containsObject:rootWindow]
        && [UIApplication sharedApplication].windows.count > 0) {
        rootWindow = [UIApplication sharedApplication].windows[0];
    }
    UIViewController *topVC = rootWindow.rootViewController;
    // 未读到keyWindow的rootViewController，则读UIApplicationDelegate的window，但该window不一定存在
    if (nil == topVC && [[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    }
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

@end
