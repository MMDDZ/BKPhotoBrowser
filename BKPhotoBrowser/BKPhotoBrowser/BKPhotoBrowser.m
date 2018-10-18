//
//  BKPhotoBrowser.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#define Photo_CollectionView_Identifier @"photo_cell"

#import "BKPhotoBrowser.h"
#import <objc/message.h>
#import "BKPhotoBrowserCollectionViewCell.h"
#import "BKPhotoBrowserCollectionViewFlowLayout.h"
#import "BKPhotoBrowserConfig.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
#import "BKPhotoBrowserIndicator.h"
#import "BKPhotoBrowserActionSheetView.h"
#import "BKPhotoBrowserTransitionAnimater.h"
#import "BKPhotoBrowserInteractiveTransition.h"

@interface BKPhotoBrowser()<UICollectionViewDataSource,UICollectionViewDelegate,UIViewControllerTransitioningDelegate>

/**
 上一个VC
 */
@property (nonatomic,weak) UIViewController * lastVC;
/**
 导航
 */
@property (nonatomic,strong) UINavigationController * nav;
/**
 显示view
 */
@property (nonatomic,strong) UICollectionView * collectionView;
/**
 加载失败image
 */
@property (nonatomic,strong) UIImage * errorImage;
/**
 交互方法
 */
@property (nonatomic,strong) BKPhotoBrowserInteractiveTransition * interactiveTransition;

/**
 索引
 */
@property (nonatomic,strong) UILabel * numLab;
/**
 索引后的阴影
 */
@property (nonatomic,strong) UIView * numLabShadowView;

/**
 进来之前 状态栏是否隐藏
 */
@property (nonatomic,assign) BOOL isStatusBarHidden;
@property (nonatomic,assign) UIStatusBarStyle statusBarStyle;//状态栏样式
@property (nonatomic,assign) BOOL statusBarHidden;//状态栏是否隐藏
@property (nonatomic,assign) UIStatusBarAnimation statusBarUpdateAnimation;//状态栏更新动画

/**
 状态栏是否隐藏(带动画)
 
 @param hidden 是否隐藏
 @param animation 动画类型
 */
-(void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation;

@end

@implementation BKPhotoBrowser

#pragma mark - 加载失败image

-(UIImage*)errorImage
{
    if (!_errorImage) {
        NSString * errorImagePath = [[NSBundle mainBundle] pathForResource:@"BKPhotoBrowser" ofType:@"bundle"];
        _errorImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/loading_error.png",errorImagePath]];
    }
    return _errorImage;
}

#pragma mark - SDWebImage 下载方法

-(void)imageIsDiskUrl:(NSString*)url complete:(void (^)(BOOL flag))complete
{
    [[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:url] completion:^(BOOL isInCache) {
        if (complete) {
            complete(isInCache);
        }
    }];
}

-(NSData*)takeImageDataInDiskWithUrl:(NSString*)url
{
    if ([url isKindOfClass:[NSData class]]) {
        return (NSData*)url;
    }
    
    NSString * originalMethodName = @"diskImageDataBySearchingAllPathsForKey:";
    
    u_int count = 0;
    Method * methods = class_copyMethodList([self class], &count);
    for (int i = 0; i < count; i++) {
        SEL methodName  = method_getName(methods[i]);
        NSString * methodString = NSStringFromSelector(methodName);
        if ([originalMethodName isEqualToString:methodString]){
            free(methods);
            NSData * data = ((id (*)(id, SEL, id))objc_msgSend)(self, methodName, url);
            return data;
        }
    }
    free(methods);
    return nil;
}

-(void)storeImageWithImageData:(NSData*)imageData url:(NSString*)url
{
    [[SDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:url];
}

-(void)downloadImageWithUrl:(NSString*)url progress:(void (^)(NSString*percentage))progress completed:(void (^)(NSString *url,NSData *imageData))completed
{
    if ([url isKindOfClass:[NSString class]]) {
        [self imageIsDiskUrl:url complete:^(BOOL flag) {
            if (flag) {
                NSData * imageData = [self takeImageDataInDiskWithUrl:url];
                if (completed) {
                    completed(url,imageData);
                }
            }else{
                [[[SDWebImageManager sharedManager] imageDownloader] downloadImageWithURL:[NSURL URLWithString:url] options:SDWebImageDownloaderLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                    
                    CGFloat imageDownLoadProgress = [[NSString stringWithFormat:@"%ld",(long)receivedSize] floatValue]/expectedSize;
                    if (progress) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            progress([NSString stringWithFormat:@"%.0f",fabs(imageDownLoadProgress) * 100]);
                        });
                    }
                    
                } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                    
                    if (finished) {
                        if (error) {
                            if (completed) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completed(url,nil);
                                });
                            }
                        }else{
                            
                            [self storeImageWithImageData:data url:url];
                            
                            if (completed) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completed(url,data);
                                });
                            }
                        }
                    }
                }];
            }
        }];
    }else{
        if (completed) {
            completed(nil,nil);
        }
    }
}

#pragma mark - 显示方法

-(void)showInVC:(UIViewController*)displayVC
{
    _lastVC = displayVC;
    self.isStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    _nav = [[UINavigationController alloc]initWithRootViewController:self];
    _nav.navigationBarHidden = YES;
    _nav.transitioningDelegate = self;
    _nav.modalPresentationStyle = UIModalPresentationCustom;
    [displayVC presentViewController:_nav animated:YES completion:nil];
    
    self.statusBarHidden = YES;
}

#pragma mark - ViewDidLoad

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.collectionView];
    
    [self initSubView];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.statusBarHidden = YES;
    
    self.nav.navigationBarHidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (!self.isStatusBarHidden) {
        self.statusBarHidden = NO;
    }
}

-(void)dealloc
{
    if (_allImageCount > 1) {
        [self.numLab removeObserver:self forKeyPath:@"text"];
    }
}

#pragma mark - BKPhotoBrowserInteractiveTransition

-(BKPhotoBrowserInteractiveTransition*)interactiveTransition
{
    if (!_interactiveTransition) {
        _interactiveTransition = [[BKPhotoBrowserInteractiveTransition alloc] init];
        _interactiveTransition.lastVC = self.lastVC.navigationController?self.lastVC.navigationController:self.lastVC;
        [_interactiveTransition addPanGestureForViewController:self];
    }
    return _interactiveTransition;
}

#pragma mark - UIViewControllerTransitioningDelegate

-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    UIImageView * imageView = [self getTapImageView];
    
    BKPhotoBrowserTransitionAnimater * transitionAnimater = [[BKPhotoBrowserTransitionAnimater alloc] initWithTransitionType:BKPhotoBrowserTransitionPresent];
    transitionAnimater.startImageView = imageView;
    transitionAnimater.endRect = [self calculateTargetFrameWithImageView:imageView];
    WEAK_SELF(self);
    [transitionAnimater setEndTransitionAnimateAction:^{
        STRONG_SELF(self);
        
        [strongSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:strongSelf.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        strongSelf.collectionView.hidden = NO;
    }];
    
    return transitionAnimater;
    
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    UIImageView * imageView = [self.delegate photoBrowser:self currentImageViewForIndex:_currentIndex];
    CGRect endRect = CGRectZero;
    if (imageView) {
        endRect = [imageView.superview convertRect:imageView.frame toView:self.view];
    }
    
    BKPhotoBrowserTransitionAnimater * transitionAnimater = [[BKPhotoBrowserTransitionAnimater alloc] initWithTransitionType:BKPhotoBrowserTransitionDismiss];
    transitionAnimater.startImageView = self.interactiveTransition.startImageView;
    transitionAnimater.endRect = endRect;
    transitionAnimater.alphaPercentage = self.interactiveTransition.interation?[self.interactiveTransition getCurrentViewAlphaPercentage]:1;
    WEAK_SELF(self);
    [transitionAnimater setEndTransitionAnimateAction:^{
        STRONG_SELF(self);
        strongSelf.collectionView.hidden = NO;
    }];
    
    return transitionAnimater;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition.interation?self.interactiveTransition:nil;
}

/**
 获取初始点击图片
 
 @return 图片
 */
-(UIImageView*)getTapImageView
{
    UIImageView * imageView = [self.delegate photoBrowser:self currentImageViewForIndex:_currentIndex];
    CGRect parentRect = [imageView.superview convertRect:imageView.frame toView:self.view];
    
    UIImageView * newImageView = [[UIImageView alloc]initWithFrame:parentRect];
    newImageView.contentMode = UIViewContentModeScaleAspectFill;
    newImageView.clipsToBounds = YES;
    if (imageView.image) {
        newImageView.image = imageView.image;
    }else{
        newImageView.image = self.errorImage;
    }
    
    return newImageView;
}

/**
 获取初始图片动画后frame
 
 @param imageView 初始点击图片
 @return frame
 */
-(CGRect)calculateTargetFrameWithImageView:(UIImageView*)imageView
{
    CGRect targetFrame = CGRectZero;
    targetFrame.size.width = self.view.frame.size.width;
    if (imageView.image) {
        CGFloat scale = imageView.image.size.width/targetFrame.size.width;
        targetFrame.size.height = imageView.image.size.height/scale;
        if (targetFrame.size.height < self.view.frame.size.height) {
            targetFrame.origin.y = (self.view.frame.size.height - targetFrame.size.height)/2;
        }
    }else{
        targetFrame.size.height = self.view.frame.size.width;
        targetFrame.origin.y = (self.view.frame.size.height - targetFrame.size.height)/2;
    }
    
    return targetFrame;
}

#pragma mark - numLab

-(UILabel*)numLab
{
    if (!_numLab) {
        _numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, self.view.frame.size.width, 20)];
        _numLab.font = [UIFont systemFontOfSize:18];
        _numLab.textAlignment = NSTextAlignmentCenter;
        _numLab.textColor = [UIColor whiteColor];
        _numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_currentIndex+1,(unsigned long)_allImageCount];
    }
    return _numLab;
}

-(UIView*)numLabShadowView
{
    if (!_numLabShadowView) {
        
        CGFloat width = [_numLab.text boundingRectWithSize:CGSizeMake(MAXFLOAT, _numLab.frame.size.height) options: NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_numLab.font} context:nil].size.width + 30;
        
        _numLabShadowView = [[UIView alloc]initWithFrame:CGRectMake((self.view.frame.size.width - width)/2.0f, 0, width, _numLab.frame.size.height+10)];
        _numLabShadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _numLabShadowView.layer.cornerRadius = _numLabShadowView.frame.size.height/2.0f;
        _numLabShadowView.clipsToBounds = YES;
        
        CGPoint center = _numLabShadowView.center;
        center.y = _numLab.center.y;
        _numLabShadowView.center = center;
    }
    return _numLabShadowView;
}

#pragma mark - 保存 & titleNum

-(void)initSubView
{
    if (_allImageCount != 1) {
        
        [self.view addSubview:self.numLab];
        [self.view addSubview:self.numLabShadowView];
        [self.view bringSubviewToFront:self.numLab];
        
        [self.numLab addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([object isEqual:self.numLab] && [keyPath isEqual:@"text"]) {
        
        if (![change[@"new"] isEqualToString:change[@"old"]]) {
            
            CGFloat width = [self.numLab.text boundingRectWithSize:CGSizeMake(MAXFLOAT, self.numLab.frame.size.height) options: NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.numLab.font} context:nil].size.width + 30;
            
            CGRect numLabShadowViewRect = self.numLabShadowView.frame;
            numLabShadowViewRect.size.width = width;
            numLabShadowViewRect.origin.x = (self.view.frame.size.width - width)/2.0f;
            self.numLabShadowView.frame = numLabShadowViewRect;
        }
    }
}

#pragma mark - UICollectionView

-(UICollectionView*)collectionView
{
    if (!_collectionView) {
        BKPhotoBrowserCollectionViewFlowLayout * flowLayout = [[BKPhotoBrowserCollectionViewFlowLayout alloc]init];
        flowLayout.allImageCount = _allImageCount;
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(-BKPhotoBrowser_ImageViewMargin, 0, self.view.frame.size.width+BKPhotoBrowser_ImageViewMargin*2, self.view.frame.size.height) collectionViewLayout:flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.hidden = YES;
        _collectionView.pagingEnabled = YES;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        [_collectionView registerClass:[BKPhotoBrowserCollectionViewCell class] forCellWithReuseIdentifier:Photo_CollectionView_Identifier];
    }
    return _collectionView;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _allImageCount;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BKPhotoBrowserCollectionViewCell * cell = (BKPhotoBrowserCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:Photo_CollectionView_Identifier forIndexPath:indexPath];
    
    UITapGestureRecognizer * deleteRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewRecognizer:)];
    deleteRecognizer.numberOfTapsRequired = 1;
    [cell.imageScrollView addGestureRecognizer:deleteRecognizer];
    
    UITapGestureRecognizer * imageScrollViewRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewRecognizer:)];
    imageScrollViewRecognizer.numberOfTapsRequired = 2;
    [cell.imageScrollView addGestureRecognizer:imageScrollViewRecognizer];
    
    [deleteRecognizer requireGestureRecognizerToFail:imageScrollViewRecognizer];
    
    UILongPressGestureRecognizer * imageScrollViewLongPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewLongPress:)];
    imageScrollViewLongPress.minimumPressDuration = 0.3;
    [cell.imageScrollView addGestureRecognizer:imageScrollViewLongPress];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_collectionView.hidden) {
        _currentIndex = indexPath.item;
    }
    
    BKPhotoBrowserCollectionViewCell * aCell = (BKPhotoBrowserCollectionViewCell*)cell;
    aCell.imageScrollView.contentSize = CGSizeMake(cell.frame.size.width-BKPhotoBrowser_ImageViewMargin*2, cell.frame.size.height);
    aCell.imageScrollView.zoomScale = 1;
    aCell.showImageView.image = nil;
    
    self.interactiveTransition.startImageView = aCell.showImageView;
    self.interactiveTransition.supperScrollView = aCell.imageScrollView;
    
    UIImageView * imageView = [self.delegate photoBrowser:self currentImageViewForIndex:indexPath.item];
    if (imageView) {
        if (imageView.image) {
            aCell.showImageView.image = imageView.image;
        }else{
            aCell.showImageView.image = self.errorImage;
        }
    }else{
        aCell.showImageView.image = self.errorImage;
    }
    CGRect targetFrame = [self calculateTargetFrameWithImageView:imageView];
    aCell.showImageView.frame = targetFrame;
    aCell.imageScrollView.contentSize = CGSizeMake(aCell.showImageView.frame.size.width, aCell.showImageView.frame.size.height);
    
    BKPhotoBrowserIndicator * oldIndicator = [aCell viewWithTag:1];
    [oldIndicator removeFromSuperview];
    
    id obj = [self.delegate photoBrowser:self dataSourceForIndex:indexPath.item];
    if ([obj isKindOfClass:[NSData class]]) {
        
        NSData * imageData = (NSData*)obj;
        [self editImageView:aCell.showImageView image:nil imageData:imageData scrollView:aCell.imageScrollView];
        
    }else if ([obj isKindOfClass:[NSString class]]) {
        
        NSURL * imageUrl = [NSURL URLWithString:obj];
        BOOL imageUrl_CanOpenFlag = [[UIApplication sharedApplication] canOpenURL:imageUrl];
        
        //如果是网络链接
        if (imageUrl_CanOpenFlag) {
            
            BKPhotoBrowserIndicator * indicator = [[BKPhotoBrowserIndicator alloc]initWithFrame:aCell.bounds];
            indicator.tag = 1;
            indicator.hidden = YES;
            [aCell addSubview:indicator];
            [indicator startAnimation];
            
            UITapGestureRecognizer * deleteRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewRecognizer:)];
            deleteRecognizer.numberOfTapsRequired = 1;
            [indicator addGestureRecognizer:deleteRecognizer];
            
            [self downloadImageWithUrl:obj progress:^(NSString *percentage) {
                indicator.hidden = NO;
                indicator.progressTitle = percentage;
            } completed:^(NSString *url, NSData *imageData) {
                [indicator stopAnimation];
                if (!url || !imageData) {} else {
                    [self editImageView:aCell.showImageView image:nil imageData:imageData scrollView:aCell.imageScrollView];
                    self.interactiveTransition.startImageView = aCell.showImageView;
                    self.interactiveTransition.supperScrollView = aCell.imageScrollView;
                }
            }];
            
        }else{
            
            NSString * imageStr = (NSString*)obj;
            
            NSString * name = @"";
            if ([imageStr containsString:@".gif"]) {
                NSRange gif_range = [imageStr rangeOfString:@".gif"];
                name = [imageStr substringWithRange:NSMakeRange(0, gif_range.location)];
            }else{
                name = imageStr;
            }
            
            NSURL * imageUrl = [[NSBundle mainBundle] URLForResource:name withExtension:@"gif"];
            if (imageUrl) {
                NSData * imageData = [NSData dataWithContentsOfURL:imageUrl];
                [self editImageView:aCell.showImageView image:nil imageData:imageData scrollView:aCell.imageScrollView];
            }else {
                [self editImageView:aCell.showImageView image:[UIImage imageNamed:name] imageData:nil scrollView:aCell.imageScrollView];
            }
            
            self.interactiveTransition.startImageView = aCell.showImageView;
            self.interactiveTransition.supperScrollView = aCell.imageScrollView;
        }
    }
}

-(void)editImageView:(FLAnimatedImageView*)showImageView image:(UIImage*)image imageData:(NSData*)imageData scrollView:(UIScrollView*)imageScrollView
{
    if (!imageData && !image) {
        return;
    }
    
    if (image) {
        showImageView.image = image;
    }
    
    if (imageData) {
        FLAnimatedImage * animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
        if (animatedImage) {
            showImageView.animatedImage = animatedImage;
        }else{
            showImageView.image = [UIImage imageWithData:imageData];
        }
    }
    
    showImageView.frame = [self calculateTargetFrameWithImageView:showImageView];
    imageScrollView.contentSize = CGSizeMake(showImageView.frame.size.width, showImageView.frame.size.height);
    
    CGFloat scale = showImageView.image.size.width / self.view.frame.size.width;
    imageScrollView.maximumZoomScale = scale<2?2:scale;
}

#pragma mark - 手势

-(void)imageScrollViewRecognizer:(UITapGestureRecognizer*)recoginzer
{
    UIScrollView * imageScrollView = (UIScrollView*)recoginzer.view;
    
    if (recoginzer.numberOfTapsRequired == 1) {
        
        [self.nav dismissViewControllerAnimated:YES completion:nil];
        
    }else if (recoginzer.numberOfTapsRequired == 2) {
        if (imageScrollView.zoomScale != 1) {
            [imageScrollView setZoomScale:1 animated:YES];
        }else{
            [imageScrollView setZoomScale:imageScrollView.maximumZoomScale animated:YES];
        }
    }
}

-(void)imageScrollViewLongPress:(UILongPressGestureRecognizer*)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        UIScrollView * imageScrollView = (UIScrollView*)longPress.view;
        [[imageScrollView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[FLAnimatedImageView class]]) {
                FLAnimatedImageView * showImageView = obj;
                if (showImageView.image) {
                    BKPhotoBrowserActionSheetView * actionSheetView = [[BKPhotoBrowserActionSheetView alloc]initActionSheetWithImage:showImageView.image];
                    WEAK_SELF(self);
                    [actionSheetView setCheckQrCodeAction:^(NSString *qrCodeContent) {
                        STRONG_SELF(self);
                        if ([strongSelf.delegate respondsToSelector:@selector(photoBrowser:qrCodeContent:photoBrowserNav:)]) {
                            [strongSelf.delegate photoBrowser:strongSelf qrCodeContent:qrCodeContent photoBrowserNav:self.nav];
                        }
                    }];
                    [self.view addSubview:actionSheetView];
                }
                *stop = YES;
            }
        }];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _collectionView) {
        
        CGPoint pInView = [self.view convertPoint:_collectionView.center toView:_collectionView];
        NSIndexPath *indexPathNow = [_collectionView indexPathForItemAtPoint:pInView];
        NSInteger item = indexPathNow.item;
        
        if (!_collectionView.hidden) {
            _currentIndex = item;
            
            BKPhotoBrowserCollectionViewCell * cell = (BKPhotoBrowserCollectionViewCell*)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_currentIndex inSection:0]];
            self.interactiveTransition.startImageView = cell.showImageView;
            self.interactiveTransition.supperScrollView = cell.imageScrollView;
        }
        
        if (_allImageCount != 1) {
            self.numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_currentIndex+1,(unsigned long)_allImageCount];
        }
    }
}

#pragma mark - 状态栏

-(void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    _statusBarStyle = statusBarStyle;
    
    [UIApplication sharedApplication].statusBarStyle = _statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)setStatusBarHidden:(BOOL)statusBarHidden
{
    _statusBarHidden = statusBarHidden;
    
    [UIApplication sharedApplication].statusBarHidden = _statusBarHidden;
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation
{
    _statusBarHidden = hidden;
    _statusBarUpdateAnimation = animation;
    
    [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:_statusBarUpdateAnimation];
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)setStatusBarUpdateAnimation:(UIStatusBarAnimation)statusBarUpdateAnimation
{
    _statusBarUpdateAnimation = statusBarUpdateAnimation;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

-(BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return self.statusBarUpdateAnimation;
}

@end
