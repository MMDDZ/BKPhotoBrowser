//
//  ViewController.m
//  BKPhotoBrowser
//
//  Created by 毕珂 on 16/7/24.
//  Copyright © 2016年 BIKE. All rights reserved.
//

#import "ViewController.h"
#import "BKPhotoBrowser.h"
#import "UIImageView+WebCache.h"

@interface ViewController ()<BKPhotoBrowserDelegate>
{
    NSArray * imageArr;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    imageArr = @[@"http://e.hiphotos.baidu.com/image/crop%3D0%2C0%2C640%2C374/sign=5c41c3d6b0a1cd1111f928608422e4cc/6609c93d70cf3bc73ba0ea0adb00baa1cc112ab7.jpg",@"http://c.hiphotos.baidu.com/image/pic/item/d50735fae6cd7b8954021f68052442a7d8330eea.jpg",@"1"];
    
    CGFloat width = (self.view.frame.size.width-30)/2.0f;
    CGFloat height = width;
    CGFloat space = 10;
    for (int i = 0 ; i<[imageArr count]; i++) {
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGFloat x = space+(space+width)*(i%2);
        CGFloat y = space+(space+height)*(i/2);
        
        button.frame = CGRectMake(x, 100 + y, width, height);
        button.tag = (i+1)*100;
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        UIImageView * imageView = [[UIImageView alloc]initWithFrame:button.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.tag = button.tag + 1;
        if (i == 2) {
            imageView.image = [UIImage imageNamed:@"1"];
        }else{
            [imageView sd_setImageWithURL:[NSURL URLWithString:imageArr[i]]];
        }
        [button addSubview:imageView];
    }
}

-(void)buttonClick:(UIButton*)button
{
    BKPhotoBrowser * photoBrowser = [[BKPhotoBrowser alloc]init];
    photoBrowser.delegate = self;
    photoBrowser.allImageCount = [imageArr count];
    photoBrowser.currentIndex = button.tag/100-1;
    [photoBrowser showInNav:self.navigationController];
}

#pragma mark - BKPhotoBrowserDelegate

-(UIImageView*)photoBrowser:(BKPhotoBrowser*)photoBrowser currentImageViewForIndex:(NSInteger)index
{
    UIButton * button = (UIButton*)[self.view viewWithTag:(index+1)*100];
    UIImageView * imageView = (UIImageView*)[button viewWithTag:button.tag + 1];
    return imageView;
}

-(id)photoBrowser:(BKPhotoBrowser *)photoBrowser dataSourceForIndex:(NSInteger)index
{
    if (index == 2) {
        return UIImageJPEGRepresentation([UIImage imageNamed:imageArr[index]], 1);
    }else{
        return imageArr[index];
    }
}

-(void)photoBrowser:(BKPhotoBrowser *)photoBrowser qrCodeContent:(NSString*)qrCodeContent
{
    NSLog(@"二维码内容 : %@",qrCodeContent);
}

@end
