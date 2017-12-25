//
//  BKPhotoBrowserTransitionAnimater.m
//  guoguanjuyanglao
//
//  Created by 毕珂 on 2017/12/17.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import "BKPhotoBrowserTransitionAnimater.h"
#import "BKPhotoBrowser.h"

@interface BKPhotoBrowserTransitionAnimater()

@property (nonatomic,assign) BKPhotoBrowserTransition type;

@end

@implementation BKPhotoBrowserTransitionAnimater

-(instancetype)initWithTransitionType:(BKPhotoBrowserTransition)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    switch (_type) {
        case BKPhotoBrowserTransitionPush:
            [self pushAnimation:transitionContext];
            break;
            
        case BKPhotoBrowserTransitionPop:
            [self popAnimation:transitionContext];
            break;
    }
}

- (void)pushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    BKPhotoBrowser * toVC = (BKPhotoBrowser *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toVC.view.alpha = 0;
    
    UIView * containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView addSubview:_startImageView];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        _startImageView.frame = _endRect;
        toVC.view.alpha = 1;
    } completion:^(BOOL finished) {
        if (self.endTransitionAnimateAction) {
            self.endTransitionAnimateAction();
        }
        [_startImageView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

- (void)popAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    BKPhotoBrowser * fromVC = (BKPhotoBrowser *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController * toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    [[fromVC.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setHidden:YES];
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if (!_isNavHidden) {
        [fromVC.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    UIView * containerView = [transitionContext containerView];
    [containerView insertSubview:toVC.view atIndex:0];
    [containerView addSubview:_startImageView];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        
        if (CGRectEqualToRect(_endRect, CGRectZero)) {
            _startImageView.alpha = 0;
            fromVC.view.alpha = 0;
        }else{
            _startImageView.frame = _endRect;
            fromVC.view.alpha = 0.3;
        }
        
    } completion:^(BOOL finished) {
        if (self.endTransitionAnimateAction) {
            self.endTransitionAnimateAction();
        }
        [transitionContext completeTransition:YES];
        [_startImageView removeFromSuperview];
    }];
}

@end
