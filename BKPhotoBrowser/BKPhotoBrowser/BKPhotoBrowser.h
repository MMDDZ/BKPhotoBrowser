//
//  BKPhotoBrowser.h
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BKPhotoBrowser : UIView

/**
 *  本地数组
 */
@property (nonatomic,strong) NSArray * localImageArr;

/**
 *  网络数组
 */
@property (nonatomic,strong) NSArray * thumbImageArr;
@property (nonatomic,strong) NSArray * originalImageArr;

/**
 *  选择的第几个
 */
@property (nonatomic,assign) NSInteger selectNum;

/**
 *  显示
 *
 *  @param view 点击的view(button或imageView)
 */
-(void)showInView:(UIView*)view;

@end
