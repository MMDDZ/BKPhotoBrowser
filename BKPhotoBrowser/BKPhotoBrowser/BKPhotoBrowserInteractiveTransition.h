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
@property (nonatomic, assign) BOOL interation;

/**
 起始imageView
 */
@property (nonatomic,strong) UIImageView * startImageView;


- (void)addPanGestureForViewController:(BKPhotoBrowser *)viewController;

@end
