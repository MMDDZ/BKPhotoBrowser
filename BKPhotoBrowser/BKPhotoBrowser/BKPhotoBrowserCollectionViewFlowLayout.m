//
//  BKPhotoBrowserCollectionViewFlowLayout.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import "BKPhotoBrowserCollectionViewFlowLayout.h"
#import "BKPhotoBrowserConfig.h"

@implementation BKPhotoBrowserCollectionViewFlowLayout

-(void)prepareLayout
{
    [super prepareLayout];
    
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.itemSize = CGSizeMake([UIScreen mainScreen].bounds.size.width+BKPhotoBrowser_ImageViewMargin*2, [UIScreen mainScreen].bounds.size.height);
    self.minimumInteritemSpacing = 0;
    self.minimumLineSpacing = 0;
}

- (CGSize)collectionViewContentSize
{
    return CGSizeMake(([UIScreen mainScreen].bounds.size.width+BKPhotoBrowser_ImageViewMargin*2)*_allImageCount, [UIScreen mainScreen].bounds.size.height);
}

@end
