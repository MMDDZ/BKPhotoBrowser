//
//  BKPhotoBrowserTransitionAnimater.h
//  guoguanjuyanglao
//
//  Created by 毕珂 on 2017/12/17.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"

typedef NS_ENUM(NSUInteger, BKPhotoBrowserTransition) {
    BKPhotoBrowserTransitionPresent = 0,
    BKPhotoBrowserTransitionDismiss,
};

@interface BKPhotoBrowserTransitionAnimater : NSObject <UIViewControllerAnimatedTransitioning>

/**
 透明百分比
 */
@property (nonatomic,assign) CGFloat alphaPercentage;
/**
 起始imageView
 */
@property (nonatomic,strong) UIImageView * startImageView;
/**
 结束点frame
 */
@property (nonatomic,assign) CGRect endRect;
/**
 转场动画完成回调
 */
@property (nonatomic,copy) void (^endTransitionAnimateAction)(void);

- (instancetype)initWithTransitionType:(BKPhotoBrowserTransition)type;

@end
