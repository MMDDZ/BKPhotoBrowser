//
//  BKPhotoBrowserInteractiveTransition.m
//  guoguanjuyanglao
//
//  Created by 毕珂 on 2017/12/17.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import "BKPhotoBrowserInteractiveTransition.h"

@interface BKPhotoBrowserInteractiveTransition()

/**
 添加手势的vc
 */
@property (nonatomic, weak) BKPhotoBrowser * vc;
/**
 图片起始位置
 */
@property (nonatomic, assign) CGRect startImageViewRect;
/**
 手势起始点
 */
@property (nonatomic, assign) CGPoint startPoint;
/**
 是否手势移动
 */
@property (nonatomic, assign) BOOL isMoveFlag;
/**
 x轴移动
 */
@property (nonatomic, assign) CGFloat xDistance;
/**
 y轴移动
 */
@property (nonatomic, assign) CGFloat yDistance;


@end

@implementation BKPhotoBrowserInteractiveTransition

-(void)setStartImageView:(UIImageView *)startImageView
{
    _startImageView = startImageView;
    _startImageViewRect = _startImageView.frame;
}

#pragma mark - 手势

- (void)addPanGestureForViewController:(BKPhotoBrowser *)viewController
{
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    self.vc = viewController;
    [viewController.view addGestureRecognizer:panGesture];
}

/**
 *  手势过渡的过程
 */
- (void)panGesture:(UIPanGestureRecognizer *)panGesture
{
    CGPoint nowPoint = [panGesture locationInView:_vc.view];
    CGFloat distance = 0;
    if (!CGPointEqualToPoint(nowPoint, CGPointZero) && !CGPointEqualToPoint(_startPoint, CGPointZero)) {
        _xDistance = (nowPoint.x - _startPoint.x);
        _yDistance = (nowPoint.y - _startPoint.y);
        distance = sqrt(pow(_xDistance, 2) + pow(_yDistance, 2));
    }
    CGFloat percentage = distance / ([UIScreen mainScreen].bounds.size.width / 2);
    if (fabs(percentage) > 1) {
        percentage = 1;
    }
    
    UIViewController * lastVC = [_vc.navigationController viewControllers][[[_vc.navigationController viewControllers] count] - 2];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            _interation = YES;
            _startPoint = [panGesture locationInView:_vc.view];
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            if (!_isMoveFlag) {
                _isMoveFlag = YES;
                [[_vc.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj setHidden:YES];
                }];
                [UIApplication sharedApplication].statusBarHidden = NO;
            }
            [[_vc.view superview] insertSubview:lastVC.view atIndex:0];
            [[_vc.view superview] addSubview:_startImageView];
            
            CGFloat scale = 1 - fabs(0.4*percentage);
            _startImageView.center = CGPointMake(CGRectGetMidX(_startImageViewRect) + _xDistance, CGRectGetMidY(_startImageViewRect) + _yDistance);
            _startImageView.transform = CGAffineTransformMakeScale(scale, scale);
            
            _vc.view.alpha = 1 - fabs(0.7*percentage);
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            _interation = NO;
            _isMoveFlag = NO;
            _startPoint = CGPointZero;
            
            if (percentage > 0.4) {
                [_vc dismissViewControllerAnimated:YES completion:nil];
            }else{
            
                CGFloat duration = 0.25 * percentage * 2;
                
                [UIView animateWithDuration:duration animations:^{
                    
                    _startImageView.center = CGPointMake(CGRectGetMidX(_startImageViewRect), CGRectGetMidY(_startImageViewRect));
                    _startImageView.transform = CGAffineTransformMakeScale(1, 1);
                    
                    _vc.view.alpha = 1;
                    
                } completion:^(BOOL finished) {
                    
                    [lastVC.view removeFromSuperview];
                    [_startImageView removeFromSuperview];
                    
                    [[_vc.view subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [obj setHidden:NO];
                    }];
                    [UIApplication sharedApplication].statusBarHidden = YES;
                }];
            }
            break;
        }
        default:
            break;
    }
}

@end
