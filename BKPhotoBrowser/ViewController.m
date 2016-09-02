//
//  ViewController.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import "ViewController.h"
#import "BKPhotoBrowser.h"
#import "UIButton+WebCache.h"

@interface ViewController ()
{
    NSArray * imageArr;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    imageArr = @[@"http://101.200.81.192:8083/Public/thumb/20160808173350651819.jpg",@"http://101.200.81.192:8083/Public/thumb/20160808173349115100.jpg"];
    
    CGFloat width = (self.view.frame.size.width-30)/2.0f;
    CGFloat height = width;
    CGFloat space = 10;
    for (int i = 0 ; i<[imageArr count]; i++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGFloat x = space+(space+width)*(i%2);
        CGFloat y = space+(space+height)*(i/2);
        
        button.frame = CGRectMake(x, y, width, height);
        button.tag = i;
        [button sd_setBackgroundImageWithURL:[NSURL URLWithString:imageArr[i]] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

-(void)buttonClick:(UIButton*)button
{
    BKPhotoBrowser * photoBrowser = [[BKPhotoBrowser alloc]init];
    photoBrowser.thumbImageArr = imageArr;
    photoBrowser.selectNum = button.tag;
    photoBrowser.originalImageArr = @[@"http://101.200.81.192:8083/Public/upfile/20160808173350651819.jpg",@"http://101.200.81.192:8083/Public/thumb/20160808173349115100.jpg"];
    [photoBrowser showInView:button];
}

@end
