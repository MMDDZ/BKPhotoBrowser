//
//  BKPhotoBrowserCollectionViewCell.m
//  guoguanjuyanglao
//
//  Created by zhaolin on 2017/12/18.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import "BKPhotoBrowserCollectionViewCell.h"
#import "BKPhotoBrowserConfig.h"

@interface BKPhotoBrowserCollectionViewCell()<UIScrollViewDelegate>

@end

@implementation BKPhotoBrowserCollectionViewCell

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        _imageScrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(BKPhotoBrowser_ImageViewMargin, 0, frame.size.width-BKPhotoBrowser_ImageViewMargin*2, frame.size.height)];
        _imageScrollView.showsHorizontalScrollIndicator = NO;
        _imageScrollView.showsVerticalScrollIndicator = NO;
        _imageScrollView.delegate = self;
        _imageScrollView.contentSize = CGSizeMake(frame.size.width-BKPhotoBrowser_ImageViewMargin*2, frame.size.height);
        _imageScrollView.minimumZoomScale = 1.0;
        _imageScrollView.maximumZoomScale = 2.0;
        [self addSubview:_imageScrollView];
        
        _showImageView = [[FLAnimatedImageView alloc]init];
        _showImageView.userInteractionEnabled = YES;
        _showImageView.clipsToBounds = YES;
        _showImageView.contentMode = UIViewContentModeScaleAspectFill;
        _showImageView.runLoopMode = NSRunLoopCommonModes;
        [_imageScrollView addSubview:_showImageView];
        
    }
    return self;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self scrollViewScale];
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _showImageView;
}

-(void)scrollViewScale
{
    _imageScrollView.contentSize = CGSizeMake(_showImageView.frame.size.width, _showImageView.frame.size.height);
    
    CGPoint center = _showImageView.center;
    
    center.x = _showImageView.frame.size.width>_imageScrollView.frame.size.width?_imageScrollView.contentSize.width/2.0f:_imageScrollView.center.x-BKPhotoBrowser_ImageViewMargin;
    center.y = _showImageView.frame.size.height>_imageScrollView.frame.size.height?_imageScrollView.contentSize.height/2.0f:_imageScrollView.center.y;
    
    _showImageView.center = center;
}

@end
