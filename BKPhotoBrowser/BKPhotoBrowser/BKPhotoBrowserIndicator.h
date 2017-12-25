//
//  BKPhotoBrowserIndicator.h
//  BKPhotoBrowserIndicator
//
//  Created by iMac on 16/9/2.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BKPhotoBrowserIndicator : UIView

@property (nonatomic,copy) NSString * progressTitle;

-(void)startAnimation;

-(void)stopAnimation;

@end
