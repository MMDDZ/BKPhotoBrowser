//
//  BKPhotoBrowserInteractiveTransition.h
//  guoguanjuyanglao
//
//  Created by 毕珂 on 2017/12/17.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BKPhotoBrowser.h"

@interface BKPhotoBrowserInteractiveTransition : UIPercentDrivenInteractiveTransition

/**
 是否是手势返回
 */
@property (nonatomic,assign) BOOL interation;
/**
 上一个界面
 */
@property (nonatomic,weak) UIViewController * lastVC;
/**
 起始imageView
 */
@property (nonatomic,strong) UIImageView * startImageView;
/**
 起始imageView父视图UIScrollView
 */
@property (nonatomic,strong) UIScrollView * supperScrollView;
/**
 状态栏是否隐藏
 */
@property (nonatomic,assign) BOOL isStatusBarHidden;

/**
 添加手势

 @param viewController 控制器
 */
-(void)addPanGestureForViewController:(BKPhotoBrowser *)viewController;
/**
 获取当前显示view的透明百分比

 @return 透明百分比
 */
-(CGFloat)getCurrentViewAlphaPercentage;

@end
