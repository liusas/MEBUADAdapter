//
//  MEBUADAdapter.m
//  MEAdvSDK
//
//  Created by 刘峰 on 2019/11/7.
//

#import "MEBUADAdapter.h"
#import <BUAdSDK/BUAdSDKManager.h>
#import <BUAdSDK/BUNativeExpressAdManager.h>
#import <BUAdSDK/BUNativeExpressAdView.h>
#import <BUAdSDK/BUAdSDK.h>
#import <BUAdSDK/BUSplashAdView.h>

@interface MEBUADAdapter ()<BUNativeExpressAdViewDelegate, BUNativeExpressRewardedVideoAdDelegate, BUSplashAdDelegate, BUNativeExpresInterstitialAdDelegate, BUNativeExpressFullscreenVideoAdDelegate>
/// 原生模板广告
@property (strong, nonatomic) NSMutableArray<__kindof BUNativeExpressAdView *> *expressAdViews;
/// 原生广告管理类
@property (strong, nonatomic) BUNativeExpressAdManager *nativeExpressAdManager;
/// 激励视频广告管理
@property (nonatomic, strong) BUNativeExpressRewardedVideoAd *rewardedVideoAd;
/// 全屏视频广告
@property (nonatomic, strong) BUNativeExpressFullscreenVideoAd *fullscreenVideoAd;
/// 插屏广告管理
@property (nonatomic, strong) BUNativeExpressInterstitialAd *interstitialAd;

/// 是否需要展示
@property (nonatomic, assign) BOOL needShow;

/// 是否展示误点按钮
@property (nonatomic, assign) BOOL showFunnyBtn;

/// 用来弹出广告的 viewcontroller
@property (nonatomic, strong) UIViewController *rootVC;

@end

@implementation MEBUADAdapter

// MARK: - override
+ (instancetype)sharedInstance {
    static MEBUADAdapter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MEBUADAdapter alloc] init];
    });
    return sharedInstance;
}

+ (void)launchAdPlatformWithAppid:(NSString *)appid {
    [BUAdSDKManager setAppID:appid];
#if DEBUG
    // Whether to open log. default is none.
    [BUAdSDKManager setLoglevel:BUAdSDKLogLevelDebug];
#endif
    [BUAdSDKManager setIsPaidApp:NO];
}

- (NSString *)networkName {
    return @"tt";
}

/// 获取广告平台类型
- (MEAdAgentType)platformType{
    return MEAdAgentTypeBUAD;
}

// MARK: - 开屏广告
- (void)preloadSplashWithPosid:(NSString *)posid {
    // 穿山甲无法预加载
}

- (BOOL)loadAndShowSplashWithPosid:(NSString *)posid {
    return [self loadAndShowSplashWithPosid:posid delay:3 bottomView:nil];
}

- (BOOL)loadAndShowSplashWithPosid:(NSString *)posid delay:(NSTimeInterval)delay bottomView:(UIView *)view  {
    UIViewController *vc = [self topVC];
    if (!vc) {
        return NO;
    }
    
    self.needShow = YES;
    self.posid = posid;
    
    CGRect frame = [UIScreen mainScreen].bounds;
    if (view != nil) {
        frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(view.frame));
        view.frame = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(view.frame), CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight(view.frame));
        [vc.view addSubview:view];
    }
    
    BUSplashAdView *splashView = [[BUSplashAdView alloc] initWithSlotID:posid frame:frame];
    // tolerateTimeout = CGFLOAT_MAX , The conversion time to milliseconds will be equal to 0
    splashView.tolerateTimeout = delay != 0 ? delay : 3;
    splashView.delegate = self;
    
    [splashView loadAdData];
    
    [vc.view addSubview:splashView];
    splashView.rootViewController = vc;
    
    return YES;
}

- (void)stopSplashRenderWithPosid:(NSString *)posid {
    self.needShow = NO;
}

// MARK: - 信息流广告
/// 信息流预加载,并存入缓存
/// @param feedWidth 信息流宽度
/// @param posId 广告位id
- (void)saveFeedCacheWithWidth:(CGFloat)feedWidth
                         posId:(NSString *)posId {
    self.needShow = NO;
    self.posid = posId;
    
    BUAdSlot *slot1 = [[BUAdSlot alloc] init];
    slot1.ID = posId;// 广告位id
    slot1.AdType = BUAdSlotAdTypeFeed;
    
    BUSize *imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];
    slot1.imgSize = imgSize;
    slot1.position = BUAdSlotPositionFeed;
    slot1.isSupportDeepLink = YES;
    
    // self.nativeExpressAdManager可以重用
    if (!self.nativeExpressAdManager) {
       self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(feedWidth, 0)];
    }
    self.nativeExpressAdManager.adslot = slot1;
    self.nativeExpressAdManager.adSize = CGSizeMake(feedWidth, 0);
    self.nativeExpressAdManager.delegate = self;
    [self.nativeExpressAdManager loadAd:1];
}

/// 显示信息流视图
/// @param feedWidth 广告位宽度
/// @param posId 广告位id
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId
                        count:(NSInteger)count {
    return [self showFeedViewWithWidth:feedWidth posId:posId count:count withDisplayTime:0];
}

/// 显示信息流视图
/// @param feedWidth 父视图feedWidth
/// @param posId 广告位id
/// @param displayTime 展示时长,0表示不限制时长
- (BOOL)showFeedViewWithWidth:(CGFloat)feedWidth
                        posId:(nonnull NSString *)posId
                        count:(NSInteger)count
              withDisplayTime:(NSTimeInterval)displayTime {
    // 取消所有请求
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
    self.needShow = YES;
    self.posid = posId;
    
    BUAdSlot *slot1 = [[BUAdSlot alloc] init];
    slot1.ID = posId;// 广告位id
    slot1.AdType = BUAdSlotAdTypeFeed;
    
    BUSize *imgSize = [BUSize sizeBy:BUProposalSize_Feed228_150];
    slot1.imgSize = imgSize;
    slot1.position = BUAdSlotPositionFeed;
    slot1.isSupportDeepLink = YES;
    
    // self.nativeExpressAdManager可以重用
    if (!self.nativeExpressAdManager) {
       self.nativeExpressAdManager = [[BUNativeExpressAdManager alloc] initWithSlot:slot1 adSize:CGSizeMake(feedWidth, 0)];
    }
    self.nativeExpressAdManager.adslot = slot1;
    self.nativeExpressAdManager.adSize = CGSizeMake(feedWidth, 0);
    self.nativeExpressAdManager.delegate = self;
    [self.nativeExpressAdManager loadAd:count];
    
    return YES;
}

/// 移除FeedView
- (void)removeFeedViewWithPosid:(NSString *)posid {
    self.needShow = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showFeedViewTimeout) object:nil];
}

// MARK: - 激励视频
- (BOOL)loadRewardVideoWithPosid:(NSString *)posid {
    self.needShow = YES;
    self.posid = posid;
    
    if (![self topVC]) {
        return NO;
    }
    
    self.needShow = YES;
    BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
    model.userId = @"";
    self.rewardedVideoAd = [[BUNativeExpressRewardedVideoAd alloc] initWithSlotID:posid rewardedVideoModel:model];
    self.rewardedVideoAd.delegate = self;
    [self.rewardedVideoAd loadAdData];
    
    return YES;
}

- (void)showRewardedVideoFromViewController:(UIViewController *)rootVC posid:(NSString *)posid {
    if (rootVC != nil) {
        self.rootVC = rootVC;
    }
    
    if (self.isTheVideoPlaying == NO && self.rewardedVideoAd.isAdValid == YES) {
        self.isTheVideoPlaying = YES;
        [self.rewardedVideoAd showAdFromRootViewController:rootVC];
        return;
    }
    
    NSError *error = [NSError errorWithDomain:@"show failed" code:0 userInfo:nil];
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.videoDelegate adapter:self videoShowFailure:error];
    }
}

/// 结束当前视频
- (void)stopCurrentVideoWithPosid:(NSString *)posid {
    self.needShow = NO;
    if (self.rewardedVideoAd.isAdValid) {
        if (self.rootVC) {
            [self.rootVC dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (BOOL)hasRewardedVideoAvailableWithPosid:(NSString *)posid {
    return self.rewardedVideoAd.isAdValid;
}

// MARK: - 全屏视频广告
/// 加载全屏视频
- (BOOL)loadFullscreenWithPosid:(NSString *)posid {
    self.needShow = YES;
    self.posid = posid;
    
    self.fullscreenVideoAd = [[BUNativeExpressFullscreenVideoAd alloc] initWithSlotID:posid];
    self.fullscreenVideoAd.delegate = self;
    [self.fullscreenVideoAd loadAdData];
    
    return YES;
}

/// 展示全屏视频
- (void)showFullscreenVideoFromViewController:(UIViewController *)rootVC posid:(NSString *)posid {
    if (rootVC != nil) {
        self.rootVC = rootVC;
    }
    
    if (self.isTheVideoPlaying == NO && self.fullscreenVideoAd.isAdValid == YES) {
        self.isTheVideoPlaying = YES;
        [self.fullscreenVideoAd showAdFromRootViewController:rootVC];
    }
}

/// 关闭当前视频
- (void)stopFullscreenVideoWithPosid:(NSString *)posid {
    self.needShow = NO;
    if (self.fullscreenVideoAd.isAdValid) {
        if (self.rootVC) {
            [self.rootVC dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

/// 全屏视频是否有效
- (BOOL)hasFullscreenVideoAvailableWithPosid:(NSString *)posid {
    return self.fullscreenVideoAd.adValid;
}

// MARK: - 插屏广告
- (BOOL)loadInterstitialWithPosid:(NSString *)posid {
    self.posid = posid;
    
    if (![self topVC]) {
        return NO;
    }
    
    self.needShow = YES;
    self.interstitialAd = [[BUNativeExpressInterstitialAd alloc] initWithSlotID:posid adSize:CGSizeMake(300, 300)];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadAdData];
    
    return YES;
}

- (void)showInterstitialFromViewController:(UIViewController *)rootVC posid:(NSString *)posid {
    if (rootVC != nil) {
        self.rootVC = rootVC;
    }
    
    if (self.interstitialAd.isAdValid) {
        [self.interstitialAd showAdFromRootViewController:rootVC];
    }
}

- (void)stopInterstitialWithPosid:(NSString *)posid {
    self.needShow = NO;
    if (self.interstitialAd.isAdValid) {
        if (self.rootVC) {
            [self.rootVC dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (BOOL)hasInterstitialAvailableWithPosid:(NSString *)posid {
    return self.interstitialAd.isAdValid;
}

#pragma mark - BUNativeExpressAdViewDelegate
- (void)nativeExpressAdSuccessToLoad:(BUNativeExpressAdManager *)nativeExpressAd views:(NSArray<__kindof BUNativeExpressAdView *> *)views {
    [self.expressAdViews removeAllObjects];//【重要】不能保存太多view，需要在合适的时机手动释放不用的，否则内存会过大
    
    [self.expressAdViews addObjectsFromArray:views];
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
        expressView.rootViewController = [self topVC];
        [expressView render];
        
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Load;
        model.st_t = AdLogAdType_Feed;
        model.so_t = self.sortType;
        model.posid = self.sceneId;
        model.network = self.networkName;
        model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        // 先保存到数据库
        [MEAdLogModel saveLogModelToRealm:model];
        // 立即上传
        [MEAdLogModel uploadImmediately];
    }];
    
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedLoadSuccess:feedViews:)]) {
        [self.feedDelegate adapterFeedLoadSuccess:self feedViews:self.expressAdViews];
    }
    
    DLog(@"【BytedanceUnion】个性化模板拉取广告成功回调");
}

- (void)nativeExpressAdFailToLoad:(BUNativeExpressAdManager *)nativeExpressAd error:(NSError *)error {
    DLog(@"信息流广告加载失败error = %@", error);
    if (self.isGetForCache == YES) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetFailed:)]) {
            [self.feedDelegate adapterFeedCacheGetFailed:error];
        }
        return;
    }
    
    if (self.needShow) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
            [self.feedDelegate adapter:self bannerShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Feed;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressAdViewRenderSuccess:(BUNativeExpressAdView *)nativeExpressAdView {
    DLog(@"信息流广告视图渲染完成");
    if (self.isGetForCache == YES) {
        // 缓存拉取的广告
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedCacheGetSuccess:feedViews:)]) {
            [self.feedDelegate adapterFeedCacheGetSuccess:self feedViews:@[nativeExpressAdView]];
        }
    } else {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedShowSuccess:feedView:)]) {
            [self.feedDelegate adapterFeedShowSuccess:self feedView:nativeExpressAdView];
        }
        
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Show;
        model.st_t = AdLogAdType_Feed;
        model.so_t = self.sortType;
        model.posid = self.sceneId;
        model.network = self.networkName;
        model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        // 先保存到数据库
        [MEAdLogModel saveLogModelToRealm:model];
        // 立即上传
        [MEAdLogModel uploadImmediately];
    }
}

- (void)nativeExpressAdViewRenderFail:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
    DLog(@"信息流广告渲染失败");
    if (self.needShow) {
        if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapter:bannerShowFailure:)]) {
            [self.feedDelegate adapter:self bannerShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Feed;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressAdViewWillShow:(BUNativeExpressAdView *)nativeExpressAdView {
    DLog(@"%s",__func__);
}

- (void)nativeExpressAdViewDidClick:(BUNativeExpressAdView *)nativeExpressAdView {
    DLog(@"%s",__func__);
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClicked:)]) {
        [self.feedDelegate adapterFeedClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Feed;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressAdViewPlayerDidPlayFinish:(BUNativeExpressAdView *)nativeExpressAdView error:(NSError *)error {
    DLog(@"%s",__func__);
}

- (void)nativeExpressAdView:(BUNativeExpressAdView *)nativeExpressAdView dislikeWithReason:(NSArray<BUDislikeWords *> *)filterWords {
    //【重要】需要在点击叉以后 在这个回调中移除视图，否则，会出现用户点击叉无效的情况
    [self.expressAdViews removeObject:nativeExpressAdView];
    DLog(@"点击广告的x了");
}

- (void)nativeExpressAdViewDidClosed:(BUNativeExpressAdView *)nativeExpressAdView {
//    NSLog(@"%s",__func__);
    DLog(@"关闭广告事件");
    if (self.feedDelegate && [self.feedDelegate respondsToSelector:@selector(adapterFeedClose:)]) {
        [self.feedDelegate adapterFeedClose:self];
    }
}

- (void)nativeExpressAdViewWillPresentScreen:(BUNativeExpressAdView *)nativeExpressAdView {
//    NSLog(@"%s",__func__);
}


#pragma mark - BUNativeExpressRewardedVideoAdDelegate

- (void)nativeExpressRewardedVideoAdDidLoad:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoLoadSuccess:)]) {
        [self.videoDelegate adapterVideoLoadSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressRewardedVideoAd:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    DLog(@"%s",__func__);
    self.rootVC = nil;
    self.isTheVideoPlaying = NO;
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.videoDelegate adapter:self videoShowFailure:error];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressRewardedVideoAdDidDownLoadVideo:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
//    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoDidDownload:)]) {
//        [self.videoDelegate adapterVideoDidDownload:self];
//    }
}

- (void)nativeExpressRewardedVideoAdViewRenderSuccess:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoDidDownload:)]) {
        [self.videoDelegate adapterVideoDidDownload:self];
    }
}

- (void)nativeExpressRewardedVideoAdViewRenderFail:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd error:(NSError *_Nullable)error {
    DLog(@"%s",__func__);
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressRewardedVideoAdWillVisible:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    self.isTheVideoPlaying = YES;
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoShowSuccess:)]) {
        [self.videoDelegate adapterVideoShowSuccess:self];
    }
}

- (void)nativeExpressRewardedVideoAdDidVisible:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdWillClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClose:)]) {
        [self.videoDelegate adapterVideoClose:self];
    }
    self.isTheVideoPlaying = NO;
    
    self.needShow = NO;
    [self.rewardedVideoAd loadAdData];
}

- (void)nativeExpressRewardedVideoAdDidClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    self.rootVC = nil;
}

- (void)nativeExpressRewardedVideoAdDidClick:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
    if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoClicked:)]) {
        [self.videoDelegate adapterVideoClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpressRewardedVideoAdDidClickSkip:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdDidPlayFinish:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *_Nullable)error {
    DLog(@"%s",__func__);
    if (error) {
        DLog(@"视频播放失败");
        self.isTheVideoPlaying = NO;
        if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
            [self.videoDelegate adapter:self videoShowFailure:error];
        }
        
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Fault;
        model.st_t = AdLogAdType_RewardVideo;
        model.so_t = self.sortType;
        model.posid = self.sceneId;
        model.network = self.networkName;
        model.type = AdLogFaultType_Render;
        model.code = error.code;
        if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
            model.msg = error.localizedDescription;
        }
        model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        // 先保存到数据库
        [MEAdLogModel saveLogModelToRealm:model];
        // 立即上传
        [MEAdLogModel uploadImmediately];
        
    } else {
        DLog(@"视频播放完毕");
        if (self.videoDelegate && [self.videoDelegate respondsToSelector:@selector(adapterVideoFinishPlay:)]) {
            [self.videoDelegate adapterVideoFinishPlay:self];
        }
    }
}

- (void)nativeExpressRewardedVideoAdServerRewardDidSucceed:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    DLog(@"%s",__func__);
}

- (void)nativeExpressRewardedVideoAdServerRewardDidFail:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    DLog(@"%s",__func__);
}

-(BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

// MARK: - BUNativeExpressFullscreenVideoAdDelegate
/**
 This method is called when video ad material loaded successfully.
 */
- (void)nativeExpressFullscreenVideoAdDidLoad:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoLoadSuccess:)]) {
        [self.fullscreenDelegate adapterFullscreenVideoLoadSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_FullVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 This method is called when video ad materia failed to load.
 @param error : the reason of error
 */
- (void)nativeExpressFullscreenVideoAd:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    self.rootVC = nil;
    self.isTheVideoPlaying = NO;
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.fullscreenDelegate adapter:self fullscreenShowFailure:error];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_FullVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 This method is called when rendering a nativeExpressAdView successed.
 */
- (void)nativeExpressFullscreenVideoAdViewRenderSuccess:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd {
}

/**
 This method is called when a nativeExpressAdView failed to render.
 @param error : the reason of error
 */
- (void)nativeExpressFullscreenVideoAdViewRenderFail:(BUNativeExpressFullscreenVideoAd *)rewardedVideoAd error:(NSError *_Nullable)error {
    self.rootVC = nil;
    self.isTheVideoPlaying = NO;
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapter:videoShowFailure:)]) {
        [self.fullscreenDelegate adapter:self fullscreenShowFailure:error];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_RewardVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 This method is called when video cached successfully.
 */
- (void)nativeExpressFullscreenVideoAdDidDownLoadVideo:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoDidDownload:)]) {
        [self.fullscreenDelegate adapterFullscreenVideoDidDownload:self];
    }
}

/**
 This method is called when video ad slot will be showing.
 */
- (void)nativeExpressFullscreenVideoAdWillVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    self.isTheVideoPlaying = YES;
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoShowSuccess:)]) {
        [self.fullscreenDelegate adapterFullscreenVideoShowSuccess:self];
    }
}

/**
 This method is called when video ad slot has been shown.
 */
- (void)nativeExpressFullscreenVideoAdDidVisible:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    
}

/**
 This method is called when video ad is clicked.
 */
- (void)nativeExpressFullscreenVideoAdDidClick:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoClicked:)]) {
        [self.fullscreenDelegate adapterFullscreenVideoClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_FullVideo;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

/**
 This method is called when the user clicked skip button.
 */
- (void)nativeExpressFullscreenVideoAdDidClickSkip:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoSkip:)]) {
        [self.fullscreenDelegate adapterFullscreenVideoSkip:self];
    }
}

/**
 This method is called when video ad is about to close.
 */
- (void)nativeExpressFullscreenVideoAdWillClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoClose:)]) {
        [self.fullscreenDelegate adapterFullscreenVideoClose:self];
    }
    self.isTheVideoPlaying = NO;
    
    self.needShow = NO;
    [self.fullscreenVideoAd loadAdData];
}

/**
 This method is called when video ad is closed.
 */
- (void)nativeExpressFullscreenVideoAdDidClose:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd {
    self.rootVC = nil;
}

/**
 This method is called when video ad play completed or an error occurred.
 @param error : the reason of error
 */
- (void)nativeExpressFullscreenVideoAdDidPlayFinish:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd didFailWithError:(NSError *_Nullable)error {
    if (error) {
        DLog(@"视频播放失败");
        self.isTheVideoPlaying = NO;
        if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapter:fullscreenShowFailure:)]) {
            [self.fullscreenDelegate adapter:self fullscreenShowFailure:error];
        }
        
        // 上报日志
        MEAdLogModel *model = [MEAdLogModel new];
        model.event = AdLogEventType_Fault;
        model.st_t = AdLogAdType_FullVideo;
        model.so_t = self.sortType;
        model.posid = self.sceneId;
        model.network = self.networkName;
        model.type = AdLogFaultType_Render;
        model.code = error.code;
        if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
            model.msg = error.localizedDescription;
        }
        model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
        // 先保存到数据库
        [MEAdLogModel saveLogModelToRealm:model];
        // 立即上传
        [MEAdLogModel uploadImmediately];
        
    } else {
        DLog(@"视频播放完毕");
        if (self.fullscreenDelegate && [self.fullscreenDelegate respondsToSelector:@selector(adapterFullscreenVideoFinishPlay:)]) {
            [self.fullscreenDelegate adapterFullscreenVideoFinishPlay:self];
        }
    }
}

/**
 This method is called when another controller has been closed.
 @param interactionType : open appstore in app or open the webpage or view video ad details page.
 */
- (void)nativeExpressFullscreenVideoAdDidCloseOtherController:(BUNativeExpressFullscreenVideoAd *)fullscreenVideoAd interactionType:(BUInteractionType)interactionType {
    
}

// MARK: - BUSplashAdDelegate
- (void)splashAdDidLoad:(BUSplashAdView *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashLoadSuccess:)]) {
        [self.splashDelegate adapterSplashLoadSuccess:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)splashAdDidClose:(BUSplashAdView *)splashAd {
    [splashAd removeFromSuperview];
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClose:)]) {
        [self.splashDelegate adapterSplashClose:self];
    }
}

- (void)splashAd:(BUSplashAdView *)splashAd didFailWithError:(NSError *)error {
    [splashAd removeFromSuperview];
    if (self.needShow) {
        if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapter:splashShowFailure:)]) {
            [self.splashDelegate adapter:self splashShowFailure:error];
        }
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)splashAdWillVisible:(BUSplashAdView *)splashAd {
    if (self.needShow == NO) {
        [splashAd removeFromSuperview];
    }
    
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashShowSuccess:)]) {
        [self.splashDelegate adapterSplashShowSuccess:self];
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Show;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)splashAdDidClick:(BUSplashAdView *)splashAd {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashClicked:)]) {
        [self.splashDelegate adapterSplashClicked:self];
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)splashAdDidCloseOtherController:(BUSplashAdView *)splashAd interactionType:(BUInteractionType)interactionType {
    if (self.splashDelegate && [self.splashDelegate respondsToSelector:@selector(adapterSplashDismiss:)]) {
        [self.splashDelegate adapterSplashDismiss:self];
    }
}

//MARK: - BUNativeExpresInterstitialAdDelegate
- (void)nativeExpresInterstitialAdDidLoad:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialLoadSuccess:)]) {
        [self.interstitialDelegate adapterInterstitialLoadSuccess:self];
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Load;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpresInterstitialAd:(BUNativeExpressInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    self.rootVC = nil;
    
    if (self.needShow) {
        if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
            [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
        }
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Normal;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpresInterstitialAdRenderSuccess:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
}

- (void)nativeExpresInterstitialAdRenderFail:(BUNativeExpressInterstitialAd *)interstitialAd error:(NSError *)error {
    DLog(@"error = %@", error);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapter:interstitialLoadFailure:)]) {
        [self.interstitialDelegate adapter:self interstitialLoadFailure:error];
    }
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Fault;
    model.st_t = AdLogAdType_Interstitial;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.type = AdLogFaultType_Render;
    model.code = error.code;
    if (error.localizedDescription != nil || error.localizedDescription.length > 0) {
        model.msg = error.localizedDescription;
    }
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpresInterstitialAdWillVisible:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialShowSuccess:)]) {
        [self.interstitialDelegate adapterInterstitialShowSuccess:self];
    }
}

- (void)nativeExpresInterstitialAdDidClick:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialClicked:)]) {
        [self.interstitialDelegate adapterInterstitialClicked:self];
    }
    
    // 上报日志
    MEAdLogModel *model = [MEAdLogModel new];
    model.event = AdLogEventType_Click;
    model.st_t = AdLogAdType_Splash;
    model.so_t = self.sortType;
    model.posid = self.sceneId;
    model.network = self.networkName;
    model.tk = [self stringMD5:[NSString stringWithFormat:@"%@%ld%@%ld", model.posid, model.so_t, @"mobi", (long)([[NSDate date] timeIntervalSince1970]*1000)]];
    // 先保存到数据库
    [MEAdLogModel saveLogModelToRealm:model];
    // 立即上传
    [MEAdLogModel uploadImmediately];
}

- (void)nativeExpresInterstitialAdWillClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialCloseFinished:)]) {
        [self.interstitialDelegate adapterInterstitialCloseFinished:self];
    }
    
    self.needShow = NO;
    [interstitialAd loadAdData];
}

- (void)nativeExpresInterstitialAdDidClose:(BUNativeExpressInterstitialAd *)interstitialAd {
    DLog(@"%s",__func__);
    self.rootVC = nil;
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialCloseFinished:)]) {
        [self.interstitialDelegate adapterInterstitialCloseFinished:self];
    }
    
    self.needShow = NO;
    [interstitialAd loadAdData];
}

- (void)nativeExpresInterstitialAdDidCloseOtherController:(BUNativeExpressInterstitialAd *)interstitialAd interactionType:(BUInteractionType)interactionType {
    if (self.interstitialDelegate && [self.interstitialDelegate respondsToSelector:@selector(adapterInterstitialDismiss:)]) {
        [self.interstitialDelegate adapterInterstitialDismiss:self];
    }
}


// MARK: - Private
- (void)showFeedViewTimeout {
    self.needShow = NO;
    // 清空所有广告视图
    [self.expressAdViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BUNativeExpressAdView *expressView = (BUNativeExpressAdView *)obj;
        [expressView removeFromSuperview];
        expressView = nil;
    }];
    [self.expressAdViews removeAllObjects];
    
//    NSError *error = [NSError errorWithDomain:@"BUADError" code:0 userInfo:@{NSLocalizedDescriptionKey: @"请求超时"}];
}

@end
