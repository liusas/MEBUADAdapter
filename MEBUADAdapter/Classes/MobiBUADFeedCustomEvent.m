//
//  MobiBUADFeedCustomEvent.m
//  MobiAdSDK
//
//  Created by 刘峰 on 2020/9/27.
//

#import "MobiBUADFeedCustomEvent.h"
#import <BUAdSDK/BUNativeExpressAdManager.h>
#import <BUAdSDK/BUNativeExpressAdView.h>
#import "MEBUADAdapter.h"

@interface MobiBUADFeedCustomEvent ()<BUNativeExpressAdViewDelegate>

/// 原生模板广告
@property (strong, nonatomic) NSMutableArray<__kindof BUNativeExpressAdView *> *expressAdViews;

/// 原生广告管理类
@property (strong, nonatomic) BUNativeExpressAdManager *nativeExpressAdManager;

@end

@implementation MobiBUADFeedCustomEvent

- (void)requestFeedWithCustomEventInfo:(NSDictionary *)info adMarkup:(NSString *)adMarkup {
    NSString *adUnitId = [info objectForKey:@"adunit"];
    CGFloat width = [[info objectForKey:@"width"] floatValue];
    NSInteger count = [[info objectForKey:@"count"] intValue];
    
    if (adUnitId == nil) {
        NSError *error =
        [NSError errorWithDomain:MobiFeedAdsSDKDomain
                            code:MobiFeedAdErrorInvalidPosid
                        userInfo:@{NSLocalizedDescriptionKey : @"Ad Unit ID cannot be nil."}];
        [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
        return;
    }
    
    self.expressAdViews = [NSMutableArray array];
    
    BUAdSlot *slot1 = [[BUAdSlot alloc] init];
    slot1.ID = adUnitId;// 广告位id
    slot1.AdType = BUAdSlotAdTypeFeed;
    
    BUSize *imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];
    slot1.imgSize = imgSize;
    slot1.position = BUAdSlotPositionFeed;
    slot1.isSupportDeepLink = YES;
    
    // self.nativeExpressAdManager可以重用
    if (!self.nativeExpressAdManager) {
       self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(width, 0)];
    }
    self.nativeExpressAdManager.adslot = slot1;
    self.nativeExpressAdManager.adSize = CGSizeMake(width, 0);
    self.nativeExpressAdManager.delegate = self;
    [self.nativeExpressAdManager loadAd:count];
}

/// 在回传信息流广告之前,
/// 需要判断这个广告是否还有效,需要在此处返回广告有效性(是否可以直接展示)
- (BOOL)hasAdAvailable {
    return YES;
}

/// 子类重写次方法,决定由谁处理展现和点击上报
/// 默认return YES;由上层adapter处理展现和点击上报,
/// 若return NO;则由子类实现trackImpression和trackClick方法,实现上报,但要保证每个广告只上报一次
- (BOOL)enableAutomaticImpressionAndClickTracking {
    return YES;
}

/// 这个方法存在的意义是聚合广告,因为聚合广告可能会出现两个广告单元用同一个广告平台加载广告
/// 在出现多个广告单元调用同一个广告平台展示广告时,我们要通知custom event类,它们的广告已经失效,当前已经有正在播放的广告
/// 当然广告失效后需要回调`[-rewardedVideoDidExpireForCustomEvent:]([MPRewardedVideoCustomEventDelegate rewardedVideoDidExpireForCustomEvent:])`方法告诉用户这个广告已不再有效
/// 并且我们要重写这个方法,让这个Custom event类能释放掉
/// 默认这个方法不会做任何事情
- (void)handleAdPlayedForCustomEventNetwork {
    [self.delegate nativeExpressAdDidExpireForCustomEvent:self];
}

/// 在激励视频系统不再需要这个custom event类时,会调用这个方法,目的是让custom event能够成功释放掉,如果能保证custom event不会造成内存泄漏,则这个方法不用重写
- (void)handleCustomEventInvalidated {
    
}

#pragma mark - BUNativeExpressAdViewDelegate
- (void)nativeExpressAdSuccessToLoad:(BUNativeExpressAdManager *)nativeExpressAd views:(NSArray<__kindof BUNativeExpressAdView *> *)views {
    [self.expressAdViews removeAllObjects];//【重要】不能保存太多view，需要在合适的时机手动释放不用的，否则内存会过大
    
    [self.expressAdViews addObjectsFromArray:views];
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
        expressView.rootViewController = [MEBUADAdapter topVC];
        [expressView render];
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdSuccessToLoadForCustomEvent:views:)]) {
        [self.delegate nativeExpressAdSuccessToLoadForCustomEvent:self views:self.expressAdViews];
    }
}

- (void)nativeExpressAdFailToLoad:(BUNativeExpressAdManager *)nativeExpressAd error:(NSError *)error {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdSuccessToLoadForCustomEvent:views:)]) {
        [self.delegate nativeExpressAdFailToLoadForCustomEvent:self error:error];
    }
}

- (void)nativeExpressAdViewRenderSuccess:(BUNativeExpressAdView *)nativeExpressAdView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderSuccessForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewRenderSuccessForCustomEvent:nativeExpressAdView];
    }
}

- (void)nativeExpressAdViewRenderFail:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewRenderFailForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewRenderFailForCustomEvent:nativeExpressAdView];
    }
}

- (void)nativeExpressAdViewWillShow:(BUNativeExpressAdView *)nativeExpressAdView {
    
}

- (void)nativeExpressAdViewDidClick:(BUNativeExpressAdView *)nativeExpressAdView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewClickedForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewClickedForCustomEvent:nativeExpressAdView];
    }
}

/**
Sent when a playerw playback status changed.
@param playerState : player state after changed
*/
- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView stateDidChanged:(BUPlayerPlayState)playerState {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewForCustomEvent:playerStatusChanged:)]) {
        [self.delegate nativeExpressAdViewForCustomEvent:nativeExpressAdView playerStatusChanged:MobiMediaPlayerStatusStoped];
    }
}

- (void)nativeExpressAdViewPlayerDidPlayFinish:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewForCustomEvent:playerStatusChanged:)]) {
        [self.delegate nativeExpressAdViewForCustomEvent:nativeExpressAdView playerStatusChanged:MobiMediaPlayerStatusStoped];
    }
}

- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterWords {
    //【重要】需要在点击叉以后 在这个回调中移除视图，否则，会出现用户点击叉无效的情况
    [self.expressAdViews removeObject:nativeExpressAdView];
}

- (void)nativeExpressAdViewDidClosed:(BUNativeExpressAdView *)nativeExpressAdView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewDidClosedCustomEvent:)]) {
        [self.delegate nativeExpressAdViewDidClosedCustomEvent:nativeExpressAdView];
    }
}

- (void)nativeExpressAdViewWillPresentScreen:(BUNativeExpressAdView *)nativeExpressAdView {
//    NSLog(@"%s",__func__);
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewWillPresentScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewWillPresentScreenForCustomEvent:nativeExpressAdView];
    }
}

/**
 This method is called when another controller has been closed.
 @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressAdViewDidCloseOtherController:(BUNativeExpressAdView *)nativeExpressAdView interactionType:(BUInteractionType)interactionType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(nativeExpressAdViewWillDissmissScreenForCustomEvent:)]) {
        [self.delegate nativeExpressAdViewWillDissmissScreenForCustomEvent:nativeExpressAdView];
    }
}


@end
