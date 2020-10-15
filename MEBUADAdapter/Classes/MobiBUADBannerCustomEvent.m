//
//  MobiBUADBannerCustomEvent.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/28.
//

#import "MobiBUADBannerCustomEvent.h"
#import <BUAdSDK/BUNativeExpressBannerView.h>

#if __has_include("MobiPub.h")
#import "MPLogging.h"
#import "MobiBannerError.h"
#endif

@interface MobiBUADBannerCustomEvent ()<BUNativeExpressBannerViewDelegate>

/// banner广告
@property(nonatomic, strong) BUNativeExpressBannerView *bannerView;

@end

@implementation MobiBUADBannerCustomEvent

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    CGFloat whRatio = [[info objectForKey:@"whRatio"] floatValue];
    NSTimeInterval interval = [[info objectForKey:@"interval"] floatValue];
    UIViewController *rootVC = [info objectForKey:@"rootVC"];
    
    
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiBannerAdsSDKDomain
                            code:MobiBannerAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
        return;
    }
    
    
    if (self.bannerView == nil) {
        CGFloat bannerHeight = size.width/whRatio;
        self.bannerView = [[BUNativeExpressBannerView alloc] initWithSlotID:adUnitId rootViewController:rootVC adSize:CGSizeMake(size.width, bannerHeight) IsSupportDeepLink:YES interval:interval];
        
        self.bannerView.frame = CGRectMake(0, 10, size.width, bannerHeight);
        self.bannerView.delegate = self;
    }

    [self.bannerView loadAdData];
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return YES;
}

//MARK: - BUNativeExpressBannerViewDelegate
- (void)nativeExpressBannerAdViewDidLoad:(BUNativeExpressBannerView *)bannerAdView {
    // 回调到上层
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didLoadAd:)]) {
        [self.delegate bannerCustomEvent:self didLoadAd:self.bannerView];
    }
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView didLoadFailWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didFailToLoadAdWithError:)]) {
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
    }
}

- (void)nativeExpressBannerAdViewRenderSuccess:(BUNativeExpressBannerView *)bannerAdView {
}

- (void)nativeExpressBannerAdViewRenderFail:(BUNativeExpressBannerView *)bannerAdView error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didFailToLoadAdWithError:)]) {
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
    }
}

- (void)nativeExpressBannerAdViewWillBecomVisible:(BUNativeExpressBannerView *)bannerAdView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:willVisible:)]) {
        [self.delegate bannerCustomEvent:self willVisible:bannerAdView];
    }
}

- (void)nativeExpressBannerAdViewDidClick:(BUNativeExpressBannerView *)bannerAdView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:didClick:)]) {
        [self.delegate bannerCustomEvent:self didClick:bannerAdView];
    }
}

- (void)nativeExpressBannerAdViewDidCloseOtherController:(BUNativeExpressBannerView *)bannerAdView interactionType:(BUInteractionType)interactionType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEventWillLeaveApplication:)]) {
        [self.delegate bannerCustomEventWillLeaveApplication:self];
    }
}

- (void)nativeExpressBannerAdView:(BUNativeExpressBannerView *)bannerAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterwords {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerCustomEvent:willClose:)]) {
        [self.delegate bannerCustomEvent:self willClose:bannerAdView];
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        bannerAdView.alpha = 0;
    } completion:^(BOOL finished) {
        [bannerAdView removeFromSuperview];
        if (self.bannerView == bannerAdView) {
            self.bannerView = nil;
        }
    }];
}

@end
