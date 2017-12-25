//
//  BKPhotoBrowserTransitionAnimater.h
//  guoguanjuyanglao
//
//  Created by 毕珂 on 2017/12/17.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, BKPhotoBrowserTransition) {
    BKPhotoBrowserTransitionPush = 0,
    BKPhotoBrowserTransitionPop,
};

@interface BKPhotoBrowserTransitionAnimater : NSObject <UIViewControllerAnimatedTransitioning>

/**
 起始imageView
 */
@property (nonatomic,strong) UIImageView * startImageView;
/**
 结束点frame
 */
@property (nonatomic,assign) CGRect endRect;
/**
 导航是否隐藏
 */
@property (nonatomic,assign) BOOL isNavHidden;
/**
 转场动画完成回调
 */
@property (nonatomic,copy) void (^endTransitionAnimateAction)(void);

- (instancetype)initWithTransitionType:(BKPhotoBrowserTransition)type;

@end
