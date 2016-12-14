//
//  BKPhotoBrowser.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#define Photo_CollectionView_Identifier @"photo_cell"

#import "BKPhotoBrowser.h"
#import "BKBrowserImageView.h"
#import "BKPhotoCollectionViewFlowLayout.h"
#import "BKPhotoBrowserConfig.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"
#import "BKBrowserIndicator.h"

@interface BKPhotoBrowser()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
{
    UILabel * numLab;
    UIView * numLabShadowView;
    BKBrowserIndicator * saveIndicator;
}

@property (nonatomic,strong) UIButton * saveBtn;

@property (nonatomic,strong) UICollectionView * photoCollectionView;

@end

@implementation BKPhotoBrowser

#pragma mark - SDWebImage

-(void)imageIsDiskUrl:(NSString*)url complete:(void (^)(BOOL flag))complete
{
    [[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:url] completion:^(BOOL isInCache) {
        if (complete) {
            complete(isInCache);
        }
    }];
}

-(UIImage*)takeImageInDiskWithUrl:(NSString*)url
{
    if ([url isKindOfClass:[UIImage class]]) {
        return (UIImage*)url;
    }
    return [[[SDWebImageManager sharedManager] imageCache] imageFromDiskCacheForKey:url];
}

-(void)storeImageWithImage:(UIImage*)image url:(NSString*)url
{
    [[SDImageCache sharedImageCache] storeImage:image forKey:url completion:^{
        
    }];
}

-(void)downloadImageWithUrl:(NSString*)url progress:(void (^)(NSString*percentage))progress completed:(void (^)(NSString *url,UIImage *image))completed
{
    if ([url isKindOfClass:[NSString class]]) {
        [self imageIsDiskUrl:url complete:^(BOOL flag) {
            if (flag) {
                UIImage * image = [self takeImageInDiskWithUrl:url];
                if (completed) {
                    completed(url,image);
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
                            
                            [self storeImageWithImage:image url:url];
                            
                            if (completed) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completed(url,image);
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

#pragma mark - 初始

-(void)dealloc
{
    if ([_thumbImageArr count] != 1 && [_thumbImageArr count] > 0) {
        [numLab removeObserver:self forKeyPath:@"text"];
    }
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

#pragma mark - 保存 & titleNum

-(void)initSubView
{
    if (_localImageArr) {
        if ([_localImageArr count] != 1) {
            numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, self.frame.size.width, 20)];
            numLab.font = [UIFont systemFontOfSize:18];
            numLab.textAlignment = NSTextAlignmentCenter;
            numLab.textColor = [UIColor whiteColor];
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_selectNum+1,(unsigned long)[_localImageArr count]];
            [self addSubview:numLab];
            
            [self initNumLabShadowView];
        }
    }else{
        if ([_thumbImageArr count] != 1) {
            numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, self.frame.size.width, 20)];
            numLab.font = [UIFont systemFontOfSize:18];
            numLab.textAlignment = NSTextAlignmentCenter;
            numLab.textColor = [UIColor whiteColor];
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_selectNum+1,(unsigned long)[_thumbImageArr count]];
            [self addSubview:numLab];
            
            [self initNumLabShadowView];
            
            [numLab addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        }
    }
    
    [self addSubview:[self saveBtn]];
}

-(void)initNumLabShadowView
{
    CGFloat width = [numLab.text boundingRectWithSize:CGSizeMake(MAXFLOAT, numLab.frame.size.height) options: NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:numLab.font} context:nil].size.width + 30;
    
    numLabShadowView = [[UIView alloc]initWithFrame:CGRectMake((self.frame.size.width - width)/2.0f, 0, width, numLab.frame.size.height+10)];
    numLabShadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    numLabShadowView.layer.cornerRadius = numLabShadowView.frame.size.height/2.0f;
    numLabShadowView.clipsToBounds = YES;
    [self addSubview:numLabShadowView];
    
    CGPoint center = numLabShadowView.center;
    center.y = numLab.center.y;
    numLabShadowView.center = center;
    
    [self bringSubviewToFront:numLab];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([object isEqual:numLab] && [keyPath isEqual:@"text"]) {
        
        if (![change[@"new"] isEqualToString:change[@"old"]]) {
            
            CGFloat width = [numLab.text boundingRectWithSize:CGSizeMake(MAXFLOAT, numLab.frame.size.height) options: NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:numLab.font} context:nil].size.width + 30;
            
            CGRect numLabShadowViewRect = numLabShadowView.frame;
            numLabShadowViewRect.size.width = width;
            numLabShadowViewRect.origin.x = (self.frame.size.width - width)/2.0f;
            numLabShadowView.frame = numLabShadowViewRect;
            
            NSInteger item = [[change[@"new"] componentsSeparatedByString:@"/"][0] integerValue]-1;
            
            if (![self.originalImageArr[item] isKindOfClass:[UIImage class]]) {
                [self getNetworkOriginalImageWithItem:item];
            }else{
                BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
                cell.imageScrollView.zoomScale = 1;
            }
        }
    }
}

#pragma mark - 保存

-(UIButton*)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveBtn.frame = CGRectMake(self.frame.size.width - 100, self.frame.size.height - 60, 80, 40);
        [_saveBtn setTitle:@"保存" forState:UIControlStateNormal];
        _saveBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        _saveBtn.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.60f];
        _saveBtn.layer.cornerRadius = 5;
        _saveBtn.clipsToBounds = YES;
        [_saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(saveBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

-(void)saveBtnClick:(UIButton*)button
{
    NSMutableString * string = [NSMutableString stringWithString:numLab?numLab.text:@"1/1"];
    NSInteger item = [[[string componentsSeparatedByString:@"/"] firstObject] integerValue]-1;
    BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
    
    if (!cell.showImageView.image) {
        return;
    }
    
    UIImageWriteToSavedPhotosAlbum(cell.showImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    saveIndicator = [[BKBrowserIndicator alloc] initWithFrame:self.bounds];
    saveIndicator.progressTitle = @"";
    [[UIApplication sharedApplication].keyWindow addSubview:saveIndicator];
    [saveIndicator startAnimation];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    [saveIndicator stopAnimation];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.60f];
    label.layer.cornerRadius = 5;
    label.clipsToBounds = YES;
    label.bounds = CGRectMake(0, 0, 100, 30);
    label.center = self.center;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldSystemFontOfSize:17];
    [[UIApplication sharedApplication].keyWindow addSubview:label];
    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:label];
    if (error) {
        label.text = @"保存失败";
    }   else {
        label.text = @"保存成功";
    }
    [label performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}

#pragma mark - 显示方法

-(void)showInView:(UIView *)view
{
    UIWindow * window = [[[UIApplication sharedApplication] delegate] window];
    self.frame = window.bounds;
    [window addSubview:self];
    
    [self addSubview:[self photoCollectionView]];
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    [self showFirstImageViewInView:view];
    
    [self initSubView];
}

-(void)showFirstImageViewInView:(UIView*)view
{
    CGRect parentRect = [view.superview convertRect:view.frame toView:self];
    
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:parentRect];
    [self addSubview:imageView];

    
    if (!_localImageArr) {
        
        [self imageIsDiskUrl:_originalImageArr[_selectNum] complete:^(BOOL flag) {
            if (flag) {
                imageView.image = [self takeImageInDiskWithUrl:_originalImageArr[_selectNum]];
                NSMutableArray * originalImageArr = [self.originalImageArr mutableCopy];
                [originalImageArr replaceObjectAtIndex:_selectNum withObject:imageView.image];
                self.originalImageArr = originalImageArr.copy;
                [self moveAnimateWithImageView:imageView isOriginal:YES];
            }else{
                imageView.image = [self getSelectImageWithView:view];
                NSMutableArray * thumbImageArr = [self.thumbImageArr mutableCopy];
                [thumbImageArr replaceObjectAtIndex:_selectNum withObject:imageView.image];
                self.thumbImageArr = thumbImageArr.copy;
                [self moveAnimateWithImageView:imageView isOriginal:NO];
            }
        }];

    }else{
        imageView.image = [self getSelectImageWithView:view];
        [self moveAnimateWithImageView:imageView isOriginal:YES];
    }
}

-(UIImage*)getSelectImageWithView:(UIView*)view
{
    UIImage * image;
    
    if ([view isKindOfClass:[UIImageView class]]) {
        image = ((UIImageView*)view).image;
    }else if ([view isKindOfClass:[UIButton class]]) {
        UIButton * button = (UIButton*)view;
        if (button.currentImage != nil) {
            image = button.imageView.image;
        }else if (button.currentBackgroundImage != nil) {
            image = button.currentBackgroundImage;
        }
    }
    return image;
}

-(void)moveAnimateWithImageView:(UIImageView*)imageView isOriginal:(BOOL)isOriginal
{
    [UIView animateWithDuration:0.35 animations:^{
        
        CGRect showImageViewFrame = imageView.frame;
        showImageViewFrame = [self imageView:imageView editImageViewSizeWithWidth:self.frame.size.width];
        
        if (showImageViewFrame.size.height <= self.frame.size.height) {
            imageView.frame = showImageViewFrame;
            imageView.center = self.center;
        }else{
            showImageViewFrame.origin.x = 0;
            showImageViewFrame.origin.y = 0;
            imageView.frame = showImageViewFrame;
        }
        
    } completion:^(BOOL finished) {
        
        [_photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_selectNum inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _photoCollectionView.hidden = NO;
            imageView.hidden = YES;
            [imageView removeFromSuperview];
            if (!isOriginal) {
                [self getNetworkOriginalImageWithItem:_selectNum];
            }
        });
    }];
}

-(CGRect)imageView:(UIImageView*)imageView editImageViewSizeWithWidth:(CGFloat)width
{
    CGRect rect = imageView.frame;
    
    rect.size.width = width;
    CGFloat scale = imageView.image.size.width/width;
    rect.size.height = imageView.image.size.height/scale;
    
    return rect;
}

#pragma mark - 显示原图

-(void)getNetworkOriginalImageWithItem:(NSInteger)item
{
    BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
    cell.imageScrollView.zoomScale = 1;
    
    if (cell) {
    
        BKBrowserIndicator * oldIndicator = [cell viewWithTag:1];
        [oldIndicator removeFromSuperview];
        
        BKBrowserIndicator * indicator = [[BKBrowserIndicator alloc]initWithFrame:cell.bounds];
        indicator.tag = 1;
        [cell addSubview:indicator];
        [indicator startAnimation];
        
        UITapGestureRecognizer * deleteRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewRecognizer:)];
        deleteRecognizer.numberOfTapsRequired = 1;
        [indicator addGestureRecognizer:deleteRecognizer];
        
        [self downloadImageWithUrl:_originalImageArr[item] progress:^(NSString *percentage) {
            
            indicator.progressTitle = percentage;
            
        } completed:^(NSString *url, UIImage *image) {
            
            [indicator stopAnimation];
            
            if (!url || !image) {
                
            }else{
                if ([_originalImageArr containsObject:url]) {
                    NSInteger index = [_originalImageArr indexOfObject:url];
                    
                    NSMutableArray * originalImageArr = [self.originalImageArr mutableCopy];
                    [originalImageArr replaceObjectAtIndex:index withObject:image];
                    self.originalImageArr = originalImageArr.copy;
                    
                    BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                    if (cell) {
                        [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
                    }
                }
            }
        }];
    }
}

#pragma mark - 相册

-(UICollectionView*)photoCollectionView
{
    if (!_photoCollectionView) {
        BKPhotoCollectionViewFlowLayout * flowLayout = [[BKPhotoCollectionViewFlowLayout alloc]init];
        flowLayout.allImageCount = [_thumbImageArr count];
        
        _photoCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(-BKPhotoBrowser_ImageViewMargin, 0, self.frame.size.width+BKPhotoBrowser_ImageViewMargin*2, self.frame.size.height) collectionViewLayout:flowLayout];
        _photoCollectionView.delegate = self;
        _photoCollectionView.dataSource = self;
        _photoCollectionView.backgroundColor = [UIColor clearColor];
        _photoCollectionView.showsVerticalScrollIndicator = NO;
        _photoCollectionView.hidden = YES;
        _photoCollectionView.pagingEnabled = YES;
        
        [_photoCollectionView registerClass:[BKBrowserImageView class] forCellWithReuseIdentifier:Photo_CollectionView_Identifier];
    }
    return _photoCollectionView;
}

#pragma mark - UICollectionViewCell

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (_localImageArr) {
        return [_localImageArr count];
    }
    return [_thumbImageArr count];
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BKBrowserImageView * cell = (BKBrowserImageView*)[collectionView dequeueReusableCellWithReuseIdentifier:Photo_CollectionView_Identifier forIndexPath:indexPath];
    
    cell.imageScrollView.contentSize = CGSizeMake(cell.frame.size.width-BKPhotoBrowser_ImageViewMargin*2, cell.frame.size.height);
    cell.imageScrollView.zoomScale = 1;
    
    cell.showImageView.image = nil;
    
    if (_localImageArr) {
        UIImage * image = _localImageArr[indexPath.item];
        [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
    }else{
        id obj = self.originalImageArr[indexPath.item];
        if ([obj isKindOfClass:[UIImage class]]) {
            [self editImageView:cell.showImageView image:obj scrollView:cell.imageScrollView];
        }else{
            [self imageIsDiskUrl:obj complete:^(BOOL flag) {
                if (flag) {
                    UIImage * originalImage = [self takeImageInDiskWithUrl:_originalImageArr[indexPath.item]];
                    NSMutableArray * originalImageArr = [self.originalImageArr mutableCopy];
                    [originalImageArr replaceObjectAtIndex:indexPath.item withObject:originalImage];
                    self.originalImageArr = originalImageArr.copy;
                    [self editImageView:cell.showImageView image:originalImage scrollView:cell.imageScrollView];
                }else{
                    
                    id obj = self.thumbImageArr[indexPath.item];
                    if ([obj isKindOfClass:[UIImage class]]) {
                        [self editImageView:cell.showImageView image:obj scrollView:cell.imageScrollView];
                    }else{
                        [self imageIsDiskUrl:obj complete:^(BOOL flag) {
                            if (flag) {
                                UIImage * thumbImage = [self takeImageInDiskWithUrl:_thumbImageArr[indexPath.item]];
                                NSMutableArray * thumbImageArr = [self.thumbImageArr mutableCopy];
                                [thumbImageArr replaceObjectAtIndex:indexPath.item withObject:thumbImage];
                                self.thumbImageArr = thumbImageArr.copy;
                                [self editImageView:cell.showImageView image:thumbImage scrollView:cell.imageScrollView];
                            }else{
                                
                                [self downloadImageWithUrl:_thumbImageArr[indexPath.item] progress:^(NSString *percentage) {
                                    
                                } completed:^(NSString *url, UIImage *image) {
                                    
                                    if (!url || !image) {
                                        
                                    }else{
                                        if ([_thumbImageArr containsObject:url]) {
                                            NSInteger index = [_thumbImageArr indexOfObject:url];
                                            
                                            NSMutableArray * thumbImageArr = [self.thumbImageArr mutableCopy];
                                            [thumbImageArr replaceObjectAtIndex:index withObject:image];
                                            self.thumbImageArr = thumbImageArr.copy;
                                            
                                            BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                                            if (cell) {
                                                [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
                                            }
                                        }
                                    }
                                }];
                            }
                        }];
                    }
                }
            }];
        }
    }
    
    UITapGestureRecognizer * deleteRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewRecognizer:)];
    deleteRecognizer.numberOfTapsRequired = 1;
    [cell.imageScrollView addGestureRecognizer:deleteRecognizer];
    
    UITapGestureRecognizer * imageScrollViewRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(imageScrollViewRecognizer:)];
    imageScrollViewRecognizer.numberOfTapsRequired = 2;
    [cell.imageScrollView addGestureRecognizer:imageScrollViewRecognizer];
    
    [deleteRecognizer requireGestureRecognizerToFail:imageScrollViewRecognizer];
    
    return cell;
}

-(void)editImageView:(UIImageView*)showImageView image:(UIImage*)image scrollView:(UIScrollView*)imageScrollView
{
    showImageView.image = image;
    
    CGRect showImageViewFrame = showImageView.frame;
    
    showImageViewFrame.size.width = imageScrollView.frame.size.width;
    CGFloat scale = image.size.width / showImageViewFrame.size.width;
    showImageViewFrame.size.height = image.size.height / scale;
    showImageViewFrame.origin.x = 0;
    showImageViewFrame.origin.y = (imageScrollView.frame.size.height-showImageViewFrame.size.height)/2.0f<0?0:(imageScrollView.frame.size.height-showImageViewFrame.size.height)/2.0f;
    showImageView.frame = showImageViewFrame;
    
    imageScrollView.contentSize = CGSizeMake(image.size.width / scale, image.size.height / scale);
}

-(void)imageScrollViewRecognizer:(UITapGestureRecognizer*)recoginzer
{
    UIScrollView * imageScrollView = (UIScrollView*)recoginzer.view;
    
    if (recoginzer.numberOfTapsRequired == 1) {
        
        [UIApplication sharedApplication].statusBarHidden = NO;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            
            [self removeFromSuperview];
        }];
    }else if (recoginzer.numberOfTapsRequired == 2) {
        if (imageScrollView.zoomScale != 1) {
            [imageScrollView setZoomScale:1 animated:YES];
        }else{
            [imageScrollView setZoomScale:imageScrollView.maximumZoomScale animated:YES];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _photoCollectionView) {
        
        CGPoint pInView = [self convertPoint:_photoCollectionView.center toView:_photoCollectionView];
        NSIndexPath *indexPathNow = [_photoCollectionView indexPathForItemAtPoint:pInView];
        NSInteger item = indexPathNow.item;
        
        if (_localImageArr) {
            if ([_localImageArr count] != 1) {
                
                numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)item+1,(unsigned long)[_localImageArr count]];
            }
        }else{
            if ([_thumbImageArr count] != 1) {
                
                numLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)item+1,(unsigned long)[_thumbImageArr count]];
            }
        }
    }
}

@end
