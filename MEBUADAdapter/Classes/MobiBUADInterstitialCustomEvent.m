//
//  MobiBUADInterstitialCustomEvent.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/27.
//

#import "MobiBUADInterstitialCustomEvent.h"
#import <BUAdSDK/BUNativeExpressInterstitialAd.h>

@interface MobiBUADInterstitialCustomEvent ()<BUNativeExpresInterstitialAdDelegate>

/// 插屏广告管理
@property (nonatomic, strong) BUNativeExpressInterstitialAd *interstitialAd;

/// 用来弹出广告的 viewcontroller
@property (nonatomic, strong) UIViewController *rootVC;

@end

@implementation MobiBUADInterstitialCustomEvent

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiInterstitialAdsSDKDomain
                            code:MobiInterstitialAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    self.interstitialAd = [[BUNativeExpressInterstitialAd alloc] initWithSlotID:adUnitId adSize:CGSizeMake(300, 300)];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAdData];
}

/**
 * Called when the interstitial should be displayed.
 *
 * This message is sent sometime after an interstitial has been successfully loaded, as a result
 * of your code calling `-[MPInterstitialAdController showFromViewController:]`. Your implementation
 * of this method should present the interstitial ad from the specified view controller.
 *
 * If you decide to [opt out of automatic impression tracking](enableAutomaticImpressionAndClickTracking), you should place your
 * manual calls to [-trackImpression]([MPInterstitialCustomEventDelegate trackImpression]) in this method to ensure correct metrics.
 *
 * @param rootViewController The controller to use to present the interstitial modally.
 *
 */
- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if (rootViewController != nil) {
        self.rootVC = rootViewController;
    }
    
    if (self.interstitialAd.isAdValid) {
        [self.interstitialAd showAdFromRootViewController:rootViewController];
        return;
    }
    
    NSError *error =
    [NSError errorWithDomain:MobiInterstitialAdsSDKDomain
                        code:MobiInterstitialAdErrorNoAdsAvailable
                    userInfo:@{NSLocalizedDescriptionKey : @"Cannot present intersitial ads. Cause interstitial ad is invalid"}];
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
}

- (BOOL)hasAdAvailable
{
    return self.interstitialAd.isAdValid;
}

/** @name Impression and Click Tracking */

/**
 * Override to opt out of automatic impression and click tracking.
 *
 * By default, the  MPInterstitialCustomEventDelegate will automatically record impressions and clicks in
 * response to the appropriate callbacks. You may override this behavior by implementing this method
 * to return `NO`.
 *
 * @warning **Important**: If you do this, you are responsible for calling the `[-trackImpression]([MPInterstitialCustomEventDelegate trackImpression])` and
 * `[-trackClick]([MPInterstitialCustomEventDelegate trackClick])` methods on the custom event delegate. Additionally, you should make sure that these
 * methods are only called **once** per ad.
 */
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return YES;
}

// MARK: - BUNativeExpresInterstitialAdDelegate
- (void)nativeExpresInterstitialAdDidLoad:(BUNativeExpressInterstitialAd *)interstitialAd {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didLoadAd:)]) {
//        [self.delegate interstitialCustomEvent:self didLoadAd:nil];
//    }
}

- (void)nativeExpresInterstitialAd:(BUNativeExpressInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    self.rootVC = nil;
    
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didFailToLoadAdWithError:)]) {
            [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:error];
        }
    }
}

- (void)nativeExpresInterstitialAdRenderSuccess:(BUNativeExpressInterstitialAd *)interstitialAd {
//    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventRenderSuccess:)]) {
//        [self.delegate interstitialCustomEventRenderSuccess:self];
//    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:didLoadAd:)]) {
        [self.delegate interstitialCustomEvent:self didLoadAd:nil];
    }
}

- (void)nativeExpresInterstitialAdRenderFail:(BUNativeExpressInterstitialAd *)interstitialAd error:(NSError *)error {
    self.rootVC = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEvent:renderFailed:)]) {
        [self.delegate interstitialCustomEvent:self renderFailed:error];
    }
}

- (void)nativeExpresInterstitialAdWillVisible:(BUNativeExpressInterstitialAd *)interstitialAd {
    self.rootVC = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillAppear:)]) {
        [self.delegate interstitialCustomEventWillAppear:self];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidAppear:)]) {
        [self.delegate interstitialCustomEventDidAppear:self];
    }
}

- (void)nativeExpresInterstitialAdDidClick:(BUNativeExpressInterstitialAd *)interstitialAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidReceiveTapEvent:)]) {
        [self.delegate interstitialCustomEventDidReceiveTapEvent:self];
    }

}

- (void)nativeExpresInterstitialAdWillClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventWillDisappear:)]) {
        [self.delegate interstitialCustomEventWillDisappear:self];
    }
}

- (void)nativeExpresInterstitialAdDidClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    self.rootVC = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidDisappear:)]) {
        [self.delegate interstitialCustomEventDidDisappear:self];
    }
}

- (void)nativeExpresInterstitialAdDidCloseOtherController:(BUNativeExpressInterstitialAd *)interstitialAd interactionType:(BUInteractionType)interactionType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(interstitialCustomEventDidDismissModal:)]) {
        [self.delegate interstitialCustomEventDidDismissModal:self];
    }
}


@end
