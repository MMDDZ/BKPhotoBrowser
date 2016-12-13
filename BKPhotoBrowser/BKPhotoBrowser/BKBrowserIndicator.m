//
//  BKBrowserIndicator.m
//  BKPhotoBrowser
//
//  Created by iMac on 16/9/2.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import "BKBrowserIndicator.h"

@interface BKBrowserIndicator()

@property (nonatomic,strong) CALayer * dotLayer;
@property (nonatomic,strong) UILabel * progressLab;

@end

@implementation BKBrowserIndicator

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        [self dotLayer];
        [self addSubview:[self progressLab]];
    }
    return self;
}

-(CALayer*)dotLayer
{
    if (!_dotLayer) {
        
        UIView * showView = [[UIView alloc]initWithFrame:self.bounds];
        showView.backgroundColor = [UIColor clearColor];
        [self addSubview:showView];
        
        CAReplicatorLayer * replicatorLayer = [CAReplicatorLayer layer];
        replicatorLayer.bounds = CGRectMake(0, 0, showView.bounds.size.width/8.0f, showView.bounds.size.width/8.0f);
        replicatorLayer.position = showView.center;
        replicatorLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75f].CGColor;
        replicatorLayer.cornerRadius = replicatorLayer.bounds.size.width/10.0f;
        replicatorLayer.masksToBounds = YES;
        [self.layer addSublayer:replicatorLayer];
        
        _dotLayer = [CALayer layer];
        _dotLayer.bounds = CGRectMake(0, 0, replicatorLayer.bounds.size.width/15.0f, replicatorLayer.bounds.size.width/15.0f);
        _dotLayer.position = CGPointMake(replicatorLayer.bounds.size.width/2.0f, replicatorLayer.bounds.size.width/4.0f);
        _dotLayer.cornerRadius = replicatorLayer.bounds.size.width/30.0f;
        _dotLayer.masksToBounds = YES;
        _dotLayer.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        _dotLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:1].CGColor;
        _dotLayer.opacity = 0;
        [replicatorLayer addSublayer:_dotLayer];
        
        int count = 12;
        replicatorLayer.instanceDelay = 1.0 / count;
        replicatorLayer.instanceCount = count;
        replicatorLayer.instanceTransform = CATransform3DMakeRotation((2 * M_PI) / count, 0, 0, 1.0);
    }
    return _dotLayer;
}

-(void)startAnimation
{
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.duration = 1;
    animation.repeatCount = MAXFLOAT;
    animation.fromValue = @(1);
    animation.toValue = @(0.01);
    [_dotLayer addAnimation:animation forKey:nil];
}

-(void)stopAnimation
{
    [self removeFromSuperview];
}

-(void)setProgressTitle:(NSString *)progressTitle
{
    _progressTitle = progressTitle;
    if (_progressLab) {
        _progressLab.text = _progressTitle;
    }
}

-(UILabel*)progressLab
{
    if (!_progressLab) {
        _progressLab = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _progressLab.textColor = [UIColor whiteColor];
        _progressLab.textAlignment = NSTextAlignmentCenter;
        _progressLab.text = @"0";
        _progressLab.font = [UIFont systemFontOfSize:8*(self.frame.size.width/414.0f)];
    }
    return _progressLab;
}

@end
