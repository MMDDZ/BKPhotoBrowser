//
//  BKPhotoBrowser.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#define Photo_CollectionView_Identifier @"photo_cell"
#define reduce 0.3

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

@property (nonatomic,strong) UICollectionView * photoCollectionView;

@end

@implementation BKPhotoBrowser

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
    return [[[SDWebImageManager sharedManager] imageCache] imageFromDiskCacheForKey:url];
}

-(void)setThumbImageArr:(NSArray *)thumbImageArr
{
    _thumbImageArr = thumbImageArr;
    
}

-(void)setOriginalImageArr:(NSArray *)originalImageArr
{
//    __block NSMutableArray * array = [NSMutableArray arrayWithArray:originalImageArr];
//    [originalImageArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [self imageIsDiskUrl:obj complete:^(BOOL flag) {
//            if (flag) {
//                [array replaceObjectAtIndex:idx withObject:[self takeImageInDiskWithUrl:obj]];
//            }
//        }];
//    }];
    _originalImageArr = originalImageArr;
}

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
    [self addSubview:self.photoCollectionView];
    
    if (_localImageArr) {
        if ([_localImageArr count] != 1) {
            numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, self.frame.size.width, 20)];
            numLab.font = [UIFont systemFontOfSize:18];
            numLab.textAlignment = NSTextAlignmentCenter;
            numLab.textColor = [UIColor whiteColor];
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",_selectNum+1,[_localImageArr count]];
            [self addSubview:numLab];
            
            [self initNumLabShadowView];
        }
    }else{
        if ([_thumbImageArr count] != 1) {
            numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, self.frame.size.width, 20)];
            numLab.font = [UIFont systemFontOfSize:18];
            numLab.textAlignment = NSTextAlignmentCenter;
            numLab.textColor = [UIColor whiteColor];
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",_selectNum+1,[_thumbImageArr count]];
            [self addSubview:numLab];
            
            [self initNumLabShadowView];
            
            [numLab addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        }
    }
    
    UIButton * saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame = CGRectMake(15, self.frame.size.height - 60, 80, 40);
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    saveBtn.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.90f];
    saveBtn.layer.cornerRadius = 5;
    saveBtn.clipsToBounds = YES;
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:saveBtn];
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
            
//            NSInteger num = [[change[@"new"] componentsSeparatedByString:@"/"][0] integerValue]-1;
            
//            [self imageIsDiskUrl:_originalImageArr[num] complete:^(BOOL flag) {
//                if (!flag) {
//                    [self getNetworkOriginalImage];
//                }
//            }];
        }
    }
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

-(void)saveBtnClick:(UIButton*)button
{
    NSMutableString * string = [NSMutableString stringWithString:numLab?numLab.text:@"1/1"];
    NSInteger item = [[[string componentsSeparatedByString:@"/"] firstObject] integerValue]-1;
    BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
    
    UIImageWriteToSavedPhotosAlbum(cell.showImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    saveIndicator = [[BKBrowserIndicator alloc] initWithFrame:self.bounds];
    [[UIApplication sharedApplication].keyWindow addSubview:saveIndicator];
    [saveIndicator startAnimation];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    [saveIndicator stopAnimation];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.90f];
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
    
    [self initSubView];
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    [self showFirstImageViewInView:view];
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
            }else{
                imageView.image = [self getSelectImageWithView:view];
            }
            [self moveAnimateWithImageView:imageView];
        }];

    }else{
        imageView.image = [self getSelectImageWithView:view];
        [self moveAnimateWithImageView:imageView];
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

-(void)moveAnimateWithImageView:(UIImageView*)imageView
{
    [UIView animateWithDuration:0.35 animations:^{
        
        CGRect showImageViewFrame = imageView.frame;
        showImageViewFrame = [self imageView:imageView editImageViewSizeWithWidth:self.frame.size.width];
        imageView.frame = showImageViewFrame;
        imageView.center = self.center;
        
    } completion:^(BOOL finished) {
        
        [_photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_selectNum inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        _photoCollectionView.hidden = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            imageView.hidden = YES;
            [imageView removeFromSuperview];
        });
    }];
}

-(CGRect)imageView:(UIImageView*)imageView editImageViewSizeWithWidth:(CGFloat)width
{
    CGRect rect = imageView.frame;
    if (imageView.image.size.width>width) {
        rect.size.width = width;
        CGFloat scale = imageView.image.size.width/width;
        rect.size.height = imageView.image.size.height/scale;
    }else{
        rect.size.width = imageView.image.size.width;
        rect.size.height = imageView.image.size.height;
    }
    return rect;
}

/**
 *  获取原图
 */
-(void)getNetworkOriginalImage
{
    NSMutableString * string = [NSMutableString stringWithString:numLab?numLab.text:@"1/1"];
    NSInteger item = [[[string componentsSeparatedByString:@"/"] firstObject] integerValue]-1;
    
    BKBrowserImageView * cell = (BKBrowserImageView*)[_photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
    
    if (cell.imageScrollView.zoomScale == reduce) {
        if (cell) {
            BKBrowserIndicator * indicator = [[BKBrowserIndicator alloc]initWithFrame:cell.frame];
            [_photoCollectionView addSubview:indicator];
            [indicator startAnimation];
            
            [cell.showImageView sd_setImageWithURL:[NSURL URLWithString:_originalImageArr[item]] placeholderImage:cell.showImageView.image completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                [indicator stopAnimation];
                
                if (!error) {
                    
                    cell.showImageView.transform = CGAffineTransformMakeScale(1, 1);
                    cell.showImageView.userInteractionEnabled = YES;
                    
                    [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
                    
                }
            }];
        }
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
    
    cell.showImageView.transform = CGAffineTransformMakeScale(1, 1);
    cell.showImageView.userInteractionEnabled = YES;
    
    if (_localImageArr) {
        
        UIImage * image = _thumbImageArr[indexPath.row];
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
                    
                    cell.showImageView.userInteractionEnabled = NO;
                    
                    id obj = self.thumbImageArr[indexPath.item];
                    if ([obj isKindOfClass:[UIImage class]]) {
                        [self editImageView:cell.showImageView image:obj scrollView:cell.imageScrollView];
                        [self getNetworkOriginalImage];
                    }else{
                        [self imageIsDiskUrl:obj complete:^(BOOL flag) {
                            if (flag) {
                                UIImage * thumbImage = [self takeImageInDiskWithUrl:_thumbImageArr[indexPath.item]];
                                NSMutableArray * thumbImageArr = [self.thumbImageArr mutableCopy];
                                [thumbImageArr replaceObjectAtIndex:indexPath.item withObject:thumbImage];
                                self.thumbImageArr = thumbImageArr.copy;
                                [self editImageView:cell.showImageView image:thumbImage scrollView:cell.imageScrollView];
                                [self getNetworkOriginalImage];
                            }else{
                                [cell.showImageView sd_setImageWithURL:[NSURL URLWithString:_thumbImageArr[indexPath.row]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                    
                                    NSMutableArray * thumbImageArr = [self.thumbImageArr mutableCopy];
                                    [thumbImageArr replaceObjectAtIndex:indexPath.item withObject:image];
                                    self.thumbImageArr = thumbImageArr.copy;
                                    
                                    [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
                                    
                                    [self getNetworkOriginalImage];
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
    showImageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGRect showImageViewFrame = showImageView.frame;
    
    if (showImageViewFrame.size.width > imageScrollView.frame.size.width) {
        
        showImageViewFrame.size.width = imageScrollView.frame.size.width;
        CGFloat scale = image.size.width/showImageViewFrame.size.width;
        showImageViewFrame.size.height = image.size.height/scale;
        showImageViewFrame.origin.x = 0;
        showImageViewFrame.origin.y = (imageScrollView.frame.size.height-showImageViewFrame.size.height)/2.0f;
        
        imageScrollView.maximumZoomScale = scale;
    }else{
        
        showImageViewFrame.origin.x = (imageScrollView.frame.size.width - image.size.width)/2.0f;
        showImageViewFrame.origin.y = (imageScrollView.frame.size.height - image.size.height)/2.0f;
        
        imageScrollView.maximumZoomScale=2.0;
    }
    
    showImageView.frame = showImageViewFrame;
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
        NSInteger item = indexPathNow.row;
        
        if (_localImageArr) {
            if ([_localImageArr count] != 1) {
                
                numLab.text = [NSString stringWithFormat:@"%ld/%ld",item+1,[_localImageArr count]];
            }
        }else{
            if ([_thumbImageArr count] != 1) {
                
                numLab.text = [NSString stringWithFormat:@"%ld/%ld",item+1,[_thumbImageArr count]];
            }
        }
    }
}

@end
