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
        self.alphaPercentage = 1;
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
        case BKPhotoBrowserTransitionPresent:
        {
            [self presentAnimation:transitionContext];
        }
            break;
        case BKPhotoBrowserTransitionDismiss:
        {
            [self dismissAnimation:transitionContext];
        }
            break;
    }
}

- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController * fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    BKPhotoBrowser * toVC = (BKPhotoBrowser *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    toVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    
    UIView * containerView = [transitionContext containerView];
    
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];
    [containerView addSubview:_startImageView];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        self.startImageView.frame = self.endRect;
        toVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    } completion:^(BOOL finished) {
        
        [self.startImageView removeFromSuperview];
        [transitionContext completeTransition:YES];
        
        if (self.endTransitionAnimateAction) {
            self.endTransitionAnimateAction();
        }
    }];
}

- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController * fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController * toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    BKPhotoBrowser * real_fromVC = nil;
    if ([fromVC isKindOfClass:[UINavigationController class]]) {
        real_fromVC = (BKPhotoBrowser*)[((UINavigationController*)fromVC).viewControllers firstObject];
        fromVC.view.backgroundColor = [UIColor colorWithWhite:1 alpha:0];
    }else{
        real_fromVC = (BKPhotoBrowser*)fromVC;
    }
    
    if (![[real_fromVC.view subviews] containsObject:self.startImageView]) {
        CGRect rect = [[self.startImageView superview] convertRect:self.startImageView.frame toView:fromVC.view];
        self.startImageView.frame = rect;
        [fromVC.view addSubview:self.startImageView];
    }
    
    [[real_fromVC.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj != self.startImageView) {
            obj.hidden = YES;
        }
    }];
    real_fromVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:self.alphaPercentage];

    UIView * containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            if (CGRectEqualToRect(self.endRect, CGRectZero)) {
                self.startImageView.alpha = 0;
            }else{
                self.startImageView.frame = self.endRect;
            }
            real_fromVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        } completion:^(BOOL finished) {
            [self.startImageView removeFromSuperview];
            [transitionContext completeTransition:YES];
            
            [[UIApplication sharedApplication].keyWindow addSubview:toVC.view];
            
            if (self.endTransitionAnimateAction) {
                self.endTransitionAnimateAction();
            }
        }];
    });
}

@end
