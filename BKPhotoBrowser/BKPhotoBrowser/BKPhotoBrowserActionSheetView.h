//
//  BKPhotoBrowserActionSheetView.h
//  guoguanjuyanglao
//
//  Created by zhaolin on 2017/12/16.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BKPhotoBrowserActionSheetView : UIView

/**
 创建方法

 @param image 图片
 @return BKPhotoBrowserActionSheetView
 */
-(instancetype)initActionSheetWithImage:(UIImage*)image;

@property (nonatomic,copy) void (^checkQrCodeAction)(NSString * qrCodeContent);

@end
