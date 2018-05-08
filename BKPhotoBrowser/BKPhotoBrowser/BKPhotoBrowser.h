//
//  BKPhotoBrowser.h
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BKPhotoBrowser;

@protocol BKPhotoBrowserDelegate <NSObject>

@required

/**
 返回当前选中索引的imageView(gif图为FLAnimatedImageView类型)

 @param photoBrowser 图片浏览器
 @param index 当前索引
 @return 当前选中索引的imageView
 */
-(UIImageView*)photoBrowser:(BKPhotoBrowser*)photoBrowser currentImageViewForIndex:(NSInteger)index;

/**
 返回当前图片的高清图或者高清图的网络地址

 @param photoBrowser 图片浏览器
 @param index 当前索引
 @return 当前图片的高清图或者高清图的网络地址
 */
-(id)photoBrowser:(BKPhotoBrowser *)photoBrowser dataSourceForIndex:(NSInteger)index;

@optional

/**
 二维码扫描内容

 @param photoBrowser 图片浏览器
 @param qrCodeContent 二维码内容
 @param photoBrowserNav 图片浏览器导航
 */
-(void)photoBrowser:(BKPhotoBrowser *)photoBrowser qrCodeContent:(NSString*)qrCodeContent photoBrowserNav:(UINavigationController*)photoBrowserNav;

@end

@interface BKPhotoBrowser : UIViewController<UINavigationControllerDelegate>

/**
 代理
 */
@property (nonatomic,assign) id<BKPhotoBrowserDelegate> delegate;

/**
 图片总数
 */
@property (nonatomic,assign) NSInteger allImageCount;

/**
 目前选择的index
 */
@property (nonatomic,assign) NSInteger currentIndex;

/**
 显示方法
 */
-(void)showInVC:(UIViewController*)displayVC;

@end
