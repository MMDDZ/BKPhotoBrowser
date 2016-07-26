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

@interface BKPhotoBrowser()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
{
    UICollectionView * photoCollectionView;
    UIView * shadowView;
    
    UILabel * numLab;
}

@end

@implementation BKPhotoBrowser

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
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(void)initSubView
{
    shadowView = [[UIView alloc]initWithFrame:self.frame];
    shadowView.backgroundColor = [UIColor blackColor];
    [self addSubview:shadowView];
    
    [self initCollectionView];
    
    if (_localImageArr) {
        if ([_localImageArr count] != 1) {
            numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 50, self.frame.size.width, 20)];
            numLab.font = [UIFont systemFontOfSize:18];
            numLab.textAlignment = NSTextAlignmentCenter;
            numLab.textColor = [UIColor whiteColor];
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",_selectNum+1,[_localImageArr count]];
            [self addSubview:numLab];
        }
    }else{
        if ([_thumbImageArr count] != 1) {
            numLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 50, self.frame.size.width, 20)];
            numLab.font = [UIFont systemFontOfSize:18];
            numLab.textAlignment = NSTextAlignmentCenter;
            numLab.textColor = [UIColor whiteColor];
            numLab.text = [NSString stringWithFormat:@"%ld/%ld",_selectNum+1,[_thumbImageArr count]];
            [self addSubview:numLab];
            
            [numLab addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        }
    }
}

-(void)initCollectionView
{
    BKPhotoCollectionViewFlowLayout * flowLayout = [[BKPhotoCollectionViewFlowLayout alloc]init];
    flowLayout.allImageCount = [_thumbImageArr count];
    
    photoCollectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(-BKPhotoBrowser_ImageViewMargin, 0, self.frame.size.width+BKPhotoBrowser_ImageViewMargin*2, self.frame.size.height) collectionViewLayout:flowLayout];
    photoCollectionView.delegate = self;
    photoCollectionView.dataSource = self;
    photoCollectionView.backgroundColor = [UIColor clearColor];
    photoCollectionView.showsVerticalScrollIndicator = NO;
    photoCollectionView.hidden = YES;
    photoCollectionView.pagingEnabled = YES;
    [self addSubview:photoCollectionView];
    
    [photoCollectionView registerClass:[BKBrowserImageView class] forCellWithReuseIdentifier:Photo_CollectionView_Identifier];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([object isEqual:numLab] && [keyPath isEqual:@"text"]) {
        
        if (![change[@"new"] isEqualToString:change[@"old"]]) {
            
            [self getNetworkOriginalImage];
        }
    }
}

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
    
    if (!_localImageArr) {
        NSURL * originalImageUrl = [NSURL URLWithString:_originalImageArr[_selectNum]];
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager diskImageExistsForURL:originalImageUrl];
        if ([manager diskImageExistsForURL:originalImageUrl]) {
            UIImage * image = [[manager imageCache] imageFromDiskCacheForKey:originalImageUrl.absoluteString];
            imageView.image = image;
        }else{
            imageView.image = [self getSelectImageWithView:view];
        }
    }else{
        imageView.image = [self getSelectImageWithView:view];
    }
    [self addSubview:imageView];
    
    [UIView animateWithDuration:0.5 animations:^{
        
        CGRect showImageViewFrame = imageView.frame;
        
        if (imageView.image.size.width>self.frame.size.width) {
            showImageViewFrame.size.width = self.frame.size.width;
            CGFloat scale = imageView.image.size.width/self.frame.size.width;
            showImageViewFrame.size.height = imageView.image.size.height/scale;
        }else{
            showImageViewFrame.size.width = imageView.image.size.width;
            showImageViewFrame.size.height = imageView.image.size.height;
        }
        
        imageView.frame = showImageViewFrame;
        
        imageView.center = self.center;
        
    } completion:^(BOOL finished) {
        
        imageView.hidden = YES;
        [imageView removeFromSuperview];
        
        [photoCollectionView setContentOffset:CGPointMake((self.frame.size.width+2*BKPhotoBrowser_ImageViewMargin)*_selectNum, 0) animated:NO];
        
        photoCollectionView.hidden = NO;
        [self getNetworkOriginalImage];
    }];
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

-(void)getNetworkOriginalImage
{
    NSMutableString * string = [NSMutableString stringWithString:numLab.text];
    NSInteger item = [[[string componentsSeparatedByString:@"/"] firstObject] integerValue]-1;
    
    BKBrowserImageView * cell = (BKBrowserImageView*)[photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]];
    
    if (cell.imageScrollView.zoomScale == 1) {
        UIActivityIndicatorView * indicatorView = [[UIActivityIndicatorView alloc]initWithFrame:cell.frame];
        indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [cell addSubview:indicatorView];
        
        if (cell) {
            [cell.showImageView sd_setImageWithURL:[NSURL URLWithString:_originalImageArr[item]] placeholderImage:cell.showImageView.image options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
                [indicatorView startAnimating];
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [indicatorView stopAnimating];
                [indicatorView removeFromSuperview];
                
                [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
            }];
        }
    }
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
    
    if (_localImageArr) {
        
        UIImage * image = _thumbImageArr[indexPath.row];
        [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
        
    }else{
        
        NSURL * originalImageUrl = [NSURL URLWithString:_originalImageArr[indexPath.row]];
        
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager diskImageExistsForURL:originalImageUrl];
        
        if ([manager diskImageExistsForURL:originalImageUrl]) {
            
            UIImage * image = [[manager imageCache] imageFromDiskCacheForKey:originalImageUrl.absoluteString];
            [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
            
        }else{
            [cell.showImageView sd_setImageWithURL:[NSURL URLWithString:_thumbImageArr[indexPath.row]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [self editImageView:cell.showImageView image:image scrollView:cell.imageScrollView];
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
    if (scrollView == photoCollectionView) {
        
        CGPoint pInView = [self convertPoint:photoCollectionView.center toView:photoCollectionView];
        NSIndexPath *indexPathNow = [photoCollectionView indexPathForItemAtPoint:pInView];
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
