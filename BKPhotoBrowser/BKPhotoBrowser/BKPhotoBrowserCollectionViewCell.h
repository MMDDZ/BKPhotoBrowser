//
//  BKPhotoBrowserCollectionViewCell.h
//  guoguanjuyanglao
//
//  Created by zhaolin on 2017/12/18.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"

@interface BKPhotoBrowserCollectionViewCell : UICollectionViewCell

@property (nonatomic,strong) UIScrollView * imageScrollView;
@property (nonatomic,strong) FLAnimatedImageView * showImageView;

@end
