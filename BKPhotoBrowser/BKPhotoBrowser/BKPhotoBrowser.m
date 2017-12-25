//
//  BKPhotoBrowser.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#define Photo_CollectionView_Identifier @"photo_cell"

#import "BKPhotoBrowser.h"
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
{
    UILabel * numLab;
    UIView * numLabShadowView;
}

/**
 导航
 */
@property (nonatomic,strong) UINavigationController * nav;
/**
 导航是否隐藏
 */
@property (nonatomic,assign) BOOL isNavHidden;
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
    return [[[SDWebImageManager sharedManager] imageCache] diskImageDataBySearchingAllPathsForKey:url];
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

-(void)showInNav:(UINavigationController*)nav
{
    _nav = nav;
    _isNavHidden = _nav.navigationBarHidden;
    if (!_isNavHidden) {
        _nav.navigationBarHidden = YES;
    }
    _nav.delegate = self;
    [_nav pushViewController:self animated:YES];
}

#pragma mark - ViewDidLoad

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.collectionView];
    
    [self initSubView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _nav.delegate = self;
    [UIApplication sharedApplication].statusBarHidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [UIApplication sharedApplication].statusBarHidden = NO;
}

-(void)dealloc
{
    if (_allImageCount > 1) {
        [numLab removeObserver:self forKeyPath:@"text"];
    }
}

#pragma mark - BKPhotoBrowserInteractiveTransition

-(BKPhotoBrowserInteractiveTransition*)interactiveTransition
{
    if (!_interactiveTransition) {
        _interactiveTransition = [[BKPhotoBrowserInteractiveTransition alloc] init];
        [_interactiveTransition addPanGestureForViewController:self];
    }
    return _interactiveTransition;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        
        UIImageView * imageView = [self getTapImageView];
        
        BKPhotoBrowserTransitionAnimater * transitionAnimater = [[BKPhotoBrowserTransitionAnimater alloc] initWithTransitionType:BKPhotoBrowserTransitionPush];
        transitionAnimater.startImageView = imageView;
        transitionAnimater.endRect = [self calculateTargetFrameWithImageView:imageView];
        WEAK_SELF(self);
        [transitionAnimater setEndTransitionAnimateAction:^{
            STRONG_SELF(self);
            
            [strongSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:strongSelf.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            
            strongSelf.collectionView.hidden = NO;
        }];
        
        return transitionAnimater;
    }else{
        
        _collectionView.hidden = YES;
        UIImageView * imageView = [self.delegate photoBrowser:self currentImageViewForIndex:_currentIndex];
        CGRect endRect = CGRectZero;
        if (imageView) {
            endRect = [imageView.superview convertRect:imageView.frame toView:self.view];
        }
        
        BKPhotoBrowserTransitionAnimater * transitionAnimater = [[BKPhotoBrowserTransitionAnimater alloc] initWithTransitionType:BKPhotoBrowserTransitionPop];
        transitionAnimater.startImageView = self.interactiveTransition.startImageView;
        transitionAnimater.endRect = endRect;
        transitionAnimater.isNavHidden = _isNavHidden;
        WEAK_SELF(self);
        [transitionAnimater setEndTransitionAnimateAction:^{
            STRONG_SELF(self);
            
            strongSelf.collectionView.hidden = NO;
        }];
        
        return transitionAnimater;
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
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

/**
 获取目前显示图片

 @return 图片
 */
-(UIImageView*)getCurrentImageView:(UIImageView*)imageView
{
    if (!imageView) {
        BKPhotoBrowserCollectionViewCell * cell = (BKPhotoBrowserCollectionViewCell*)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_currentIndex inSection:0]];
        imageView = cell.showImageView;
    }
    
    CGRect imageRect = [self calculateTargetFrameWithImageView:imageView];
    
    UIImageView * newImageView = [[UIImageView alloc]initWithFrame:imageRect];
    newImageView.contentMode = UIViewContentModeScaleAspectFill;
    newImageView.clipsToBounds = YES;
    if (imageView.image) {
        newImageView.image = imageView.image;
    }else{
        newImageView.image = self.errorImage;
    }
    
    return newImageView;
}

#pragma mark - 保存 & titleNum

-(void)initSubView
{
    if (_allImageCount != 1) {

        numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, self.view.frame.size.width, 20)];
        numLab.font = [UIFont systemFontOfSize:18];
        numLab.textAlignment = NSTextAlignmentCenter;
        numLab.textColor = [UIColor whiteColor];
        numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_currentIndex+1,(unsigned long)_allImageCount];
        [self.view addSubview:numLab];

        [self initNumLabShadowView];

        [numLab addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
}

-(void)initNumLabShadowView
{
    CGFloat width = [numLab.text boundingRectWithSize:CGSizeMake(MAXFLOAT, numLab.frame.size.height) options: NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:numLab.font} context:nil].size.width + 30;

    numLabShadowView = [[UIView alloc]initWithFrame:CGRectMake((self.view.frame.size.width - width)/2.0f, 0, width, numLab.frame.size.height+10)];
    numLabShadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    numLabShadowView.layer.cornerRadius = numLabShadowView.frame.size.height/2.0f;
    numLabShadowView.clipsToBounds = YES;
    [self.view addSubview:numLabShadowView];

    CGPoint center = numLabShadowView.center;
    center.y = numLab.center.y;
    numLabShadowView.center = center;

    [self.view bringSubviewToFront:numLab];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([object isEqual:numLab] && [keyPath isEqual:@"text"]) {

        if (![change[@"new"] isEqualToString:change[@"old"]]) {

            CGFloat width = [numLab.text boundingRectWithSize:CGSizeMake(MAXFLOAT, numLab.frame.size.height) options: NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:numLab.font} context:nil].size.width + 30;

            CGRect numLabShadowViewRect = numLabShadowView.frame;
            numLabShadowViewRect.size.width = width;
            numLabShadowViewRect.origin.x = (self.view.frame.size.width - width)/2.0f;
            numLabShadowView.frame = numLabShadowViewRect;
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

    cell.imageScrollView.contentSize = CGSizeMake(cell.frame.size.width-BKPhotoBrowser_ImageViewMargin*2, cell.frame.size.height);
    cell.imageScrollView.zoomScale = 1;

    cell.showImageView.image = nil;

    UIImageView * imageView = [self.delegate photoBrowser:self currentImageViewForIndex:indexPath.item];
    if (imageView) {
        if (imageView.image) {
            cell.showImageView.image = imageView.image;
        }else{
            cell.showImageView.image = self.errorImage;
        }
    }else{
        cell.showImageView.image = self.errorImage;
    }
    CGRect targetFrame = [self calculateTargetFrameWithImageView:imageView];
    cell.showImageView.frame = targetFrame;
    cell.imageScrollView.contentSize = CGSizeMake(cell.showImageView.frame.size.width, cell.showImageView.frame.size.height);

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
    aCell.imageScrollView.zoomScale = 1;

    self.interactiveTransition.startImageView = [self getCurrentImageView:aCell.showImageView];

    BKPhotoBrowserIndicator * oldIndicator = [aCell viewWithTag:1];
    [oldIndicator removeFromSuperview];
    
    id obj = [self.delegate photoBrowser:self dataSourceForIndex:indexPath.item];
    if ([obj isKindOfClass:[NSData class]]) {
        
        NSData * imageData = (NSData*)obj;
        [self editImageView:aCell.showImageView imageData:imageData scrollView:aCell.imageScrollView];
        
    }else if ([obj isKindOfClass:[NSString class]]) {
        
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
                [self editImageView:aCell.showImageView imageData:imageData scrollView:aCell.imageScrollView];
                self.interactiveTransition.startImageView = [self getCurrentImageView:aCell.showImageView];
            }
        }];
    }
}

-(void)editImageView:(FLAnimatedImageView*)showImageView imageData:(NSData*)imageData scrollView:(UIScrollView*)imageScrollView
{
    FLAnimatedImage * animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
    CGSize imageSize = CGSizeZero;
    if (animatedImage) {
        showImageView.animatedImage = animatedImage;
        imageSize = animatedImage.size;
    }else{
        showImageView.image = [UIImage imageWithData:imageData];
        imageSize = showImageView.image.size;
    }

    CGRect showImageViewFrame = showImageView.frame;

    showImageViewFrame.size.width = imageScrollView.frame.size.width;
    CGFloat scale = imageSize.width / showImageViewFrame.size.width;
    showImageViewFrame.size.height = imageSize.height / scale;
    showImageViewFrame.origin.x = 0;
    showImageViewFrame.origin.y = (imageScrollView.frame.size.height-showImageViewFrame.size.height)/2.0f<0?0:(imageScrollView.frame.size.height-showImageViewFrame.size.height)/2.0f;
    showImageView.frame = showImageViewFrame;

    imageScrollView.contentSize = CGSizeMake(imageSize.width / scale, imageSize.height / scale);
}

#pragma mark - 手势

-(void)imageScrollViewRecognizer:(UITapGestureRecognizer*)recoginzer
{
    UIScrollView * imageScrollView = (UIScrollView*)recoginzer.view;

    if (recoginzer.numberOfTapsRequired == 1) {

        [self.nav popViewControllerAnimated:YES];
        
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
                        
                        _nav.delegate = nil;
                        
                        if ([strongSelf.delegate respondsToSelector:@selector(photoBrowser:qrCodeContent:)]) {
                            [strongSelf.delegate photoBrowser:strongSelf qrCodeContent:qrCodeContent];
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
            self.interactiveTransition.startImageView = [self getCurrentImageView:nil];
        }

        if (_allImageCount != 1) {
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_currentIndex+1,(unsigned long)_allImageCount];
        }
    }
}

@end
