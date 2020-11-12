//
//  MobiBUADSplashCustomEvent.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/27.
//

#import "MobiBUADSplashCustomEvent.h"
#import <BUAdSDK/BUSplashAdView.h>

@interface MobiBUADSplashCustomEvent ()<BUSplashAdDelegate>

@property (nonatomic, strong) BUSplashAdView *splashView;
@property (nonatomic, strong) UIViewController *rootVC;
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UIButton *customSkipBtn;

@end

@implementation MobiBUADSplashCustomEvent

- (void)requestSplashWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    UIView *bottomView = [info objectForKey:@"bottomView"];
    NSTimeInterval delay = [[info objectForKey:@"delay"] floatValue];
    
    BOOL hideSkipBtn = NO;
    if ([self.localExtras[@"hideSkipBtn"] boolValue] == YES) {
        hideSkipBtn = YES;
    }
    
    if (adUnitId == nil) {
        NSError *error = [NSError splashErrorWithCode:MobiSplashAdErrorNoAdsAvailable localizedDescription:@"posid cannot be nil"];
        if ([self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
            [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
        }
        return;
    }
    
    UIViewController *vc = [self topVC];
    
    if ([NSStringFromClass(vc.class) containsString:@"BUNative"]) {
        vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    if (!vc) {
        return;
    }
    
    CGRect frame = [UIScreen mainScreen].bounds;
    if (bottomView != nil) {
        frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(bottomView.frame));
        bottomView.frame = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(bottomView.frame), CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight(bottomView.frame));
        [vc.view addSubview:bottomView];
        self.bottomView = bottomView;
    }
    
    self.rootVC = vc;
    
//    BUSplashAdView *splashView = [[BUSplashAdView alloc] initWithSlotID:@"800546808" frame:frame];
    BUSplashAdView *splashView = [[BUSplashAdView alloc] initWithSlotID:adUnitId frame:frame];
    // tolerateTimeout = CGFLOAT_MAX , The conversion time to milliseconds will be equal to 0
    splashView.tolerateTimeout = delay != 0 ? delay : 3;
    splashView.delegate = self;
    splashView.hideSkipButton = hideSkipBtn;
    [splashView loadAdData];
    self.splashView = splashView;
    [self.rootVC.view addSubview:self.splashView];
    self.splashView.rootViewController = self.rootVC;
    
    BOOL isPhoneX = NO;
    if (@available(iOS 11.0, *)) {\
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
    }
    
    if (hideSkipBtn) {
        float width = 30;
        float x = splashView.frame.origin.x + splashView.frame.size.width - width - 20;
        float y = splashView.frame.origin.y + isPhoneX ? 44 + 20 : 20;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:self.localExtras[@"closeImage"] forState:UIControlStateNormal];
        button.frame = CGRectMake(x, y, width, width);
//        button.backgroundColor = UIColor.whiteColor;
        button.layer.cornerRadius = width /2.f;
        [splashView addSubview:button];
        
        [button addTarget:self action:@selector(skipBtnClick) forControlEvents:UIControlEventTouchUpInside];
        self.customSkipBtn = button;
    }
}

- (void)presentSplashFromWindow:(UIWindow *)window {
}

- (BOOL)hasAdAvailable
{
    return self.splashView.adValid;
}

- (void)handleAdPlayedForCustomEventNetwork
{
    if (!self.splashView.adValid) {
        [self.delegate splashAdDidExpireForCustomEvent:self];
    }
}

- (void)handleCustomEventInvalidated
{
}

// MARK: - BUSplashAdDelegate
- (void)splashAdDidLoad:(BUSplashAdView *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidLoadForCustomEvent:)]) {
        [self.delegate splashAdDidLoadForCustomEvent:self];
    }
}

/**
 This method is called when spalashAd skip button  is clicked.
 */
- (void)splashAdDidClickSkip:(BUSplashAdView *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdDidClickSkipForCustomEvent:)]) {
        [self.delegate splashAdDidClickSkipForCustomEvent:self];
    }
}

- (void)splashAdWillClose:(BUSplashAdView *)splashAd {
    if (!self.customSkipBtn) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdWillClosedForCustomEvent:)]) {
            [self.delegate splashAdWillClosedForCustomEvent:self];
        }
    }
}

- (void)splashAdDidClose:(BUSplashAdView *)splashAd {
    if (!self.customSkipBtn) {
        [self.bottomView removeFromSuperview];
        [splashAd removeFromSuperview];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdClosedForCustomEvent:)]) {
            [self.delegate splashAdClosedForCustomEvent:self];
        }
    }
    
}

- (void)splashAd:(BUSplashAdView *)splashAd didFailWithError:(NSError *)error {
    [self.bottomView removeFromSuperview];
    [splashAd removeFromSuperview];
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdFailToPresentForCustomEvent:withError:)]) {
        [self.delegate splashAdFailToPresentForCustomEvent:self withError:error];
    }
    
}

- (void)splashAdWillVisible:(BUSplashAdView *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdSuccessPresentScreenForCustomEvent:)]) {
        [self.delegate splashAdSuccessPresentScreenForCustomEvent:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdExposuredForCustomEvent:)]) {
        [self.delegate splashAdExposuredForCustomEvent:self];
    }
}

- (void)splashAdDidClick:(BUSplashAdView *)splashAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdClickedForCustomEvent:)]) {
        [self.delegate splashAdClickedForCustomEvent:self];
    }
}

- (void)splashAdDidCloseOtherController:(BUSplashAdView *)splashAd interactionType:(BUInteractionType)interactionType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdWillDismissFullScreenModalForCustomEvent:)]) {
        [self.delegate splashAdWillDismissFullScreenModalForCustomEvent:self];
    }
}

- (void)splashAdCountdownToZero:(BUSplashAdView *)splashAd {
    
}


/// 获取顶层VC
- (UIViewController *)topVC {
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

- (void)skipBtnClick {
    [self.bottomView removeFromSuperview];
    [self.splashView removeFromSuperview];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdWillClosedForCustomEvent:)]) {
        [self.delegate splashAdWillClosedForCustomEvent:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(splashAdClosedForCustomEvent:)]) {
        [self.delegate splashAdClosedForCustomEvent:self];
    }
}


@end
