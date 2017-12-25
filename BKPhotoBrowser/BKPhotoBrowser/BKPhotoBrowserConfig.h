//
//  BKPhotoBrowserConfig.h
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#ifndef BKPhotoBrowserConfig_h
#define BKPhotoBrowserConfig_h

//两个照片之间的距离
#define BKPhotoBrowser_ImageViewMargin 10

#define POINTS_FROM_PIXELS(__PIXELS) (__PIXELS / [[UIScreen mainScreen] scale])
#define ONE_PIXEL POINTS_FROM_PIXELS(1.0)

#define WEAK_SELF(obj) __weak typeof(obj) weakSelf = obj;
#define STRONG_SELF(obj) __strong typeof(obj) strongSelf = weakSelf;

#endif /* BKPhotoBrowserConfig_h */
