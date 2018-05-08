//
//  BKPhotoBrowserActionSheetView.m
//  guoguanjuyanglao
//
//  Created by zhaolin on 2017/12/16.
//  Copyright © 2017年 zhaolin. All rights reserved.
//

#import "BKPhotoBrowserActionSheetView.h"
#import "BKPhotoBrowserIndicator.h"
#import <Photos/Photos.h>
#import "BKPhotoBrowserConfig.h"

@interface BKPhotoBrowserActionSheetView()

@property (nonatomic,strong) UIImage * targetImage;
@property (nonatomic,copy) NSString * qrCodeContent;

@property (nonatomic,strong) UIView * shadowView;
@property (nonatomic,strong) UIView * alertView;

@property (nonatomic,strong) BKPhotoBrowserIndicator * browserIndicator;//加载菊花

@end

@implementation BKPhotoBrowserActionSheetView

-(instancetype)initActionSheetWithImage:(UIImage*)image
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _targetImage = image;
        
        [self addSubview:self.shadowView];
        [self addSubview:self.alertView];
        [self showAnimate];
    }
    return self;
}

#pragma mark - 添加 删除

-(void)showAnimate
{
    if (![UIApplication sharedApplication].keyWindow.userInteractionEnabled) {
        return;
    }
    [UIApplication sharedApplication].keyWindow.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect alertFrame = self.alertView.frame;
        alertFrame.origin.y = self.frame.size.height - self.alertView.frame.size.height;
        self.alertView.frame = alertFrame;
    } completion:^(BOOL finished) {
        [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
    }];
}

-(void)hideAnimate
{
    if (![UIApplication sharedApplication].keyWindow.userInteractionEnabled) {
        return;
    }
    [UIApplication sharedApplication].keyWindow.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect alertFrame = self.alertView.frame;
        alertFrame.origin.y = self.frame.size.height;
        self.alertView.frame = alertFrame;
    } completion:^(BOOL finished) {
        [UIApplication sharedApplication].keyWindow.userInteractionEnabled = YES;
        [self removeFromSuperview];
    }];
}

#pragma mark - shadowView

-(UIView*)shadowView
{
    if (!_shadowView) {
        _shadowView = [[UIView alloc]initWithFrame:self.bounds];
        _shadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        
        UITapGestureRecognizer * shadowTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(shadowTap)];
        [_shadowView addGestureRecognizer:shadowTap];
    }
    return _shadowView;
}

-(void)shadowTap
{
    [self hideAnimate];
}

#pragma mark - alertView

-(UIView*)alertView
{
    if (!_alertView) {
        _alertView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 0)];
        
        _qrCodeContent = [self isHaveQrCode];
        if ([_qrCodeContent length] > 0) {
            
            UIButton * firstButton = [self createSubBtnWithTitle:@"保存图片" topY:0 actionMethod:@selector(saveImage) haveBottomLine:YES];
            UIButton * secondButton = [self createSubBtnWithTitle:@"识别图中二维码" topY:CGRectGetMaxY(firstButton.frame) actionMethod:@selector(checkQrCode) haveBottomLine:NO];
            UIButton * thirdButton = [self createSubBtnWithTitle:@"取消" topY:CGRectGetMaxY(secondButton.frame) + 5 actionMethod:@selector(hideAnimate) haveBottomLine:NO];
            
            CGRect alertFrame = self.alertView.frame;
            alertFrame.size.height = CGRectGetMaxY(thirdButton.frame);
            self.alertView.frame = alertFrame;
            
        }else{
            
            UIButton * firstButton = [self createSubBtnWithTitle:@"保存图片" topY:0 actionMethod:@selector(saveImage) haveBottomLine:NO];
            UIButton * secondButton = [self createSubBtnWithTitle:@"取消" topY:CGRectGetMaxY(firstButton.frame) + 5 actionMethod:@selector(hideAnimate) haveBottomLine:NO];
            
            CGRect alertFrame = self.alertView.frame;
            alertFrame.size.height = CGRectGetMaxY(secondButton.frame);
            self.alertView.frame = alertFrame;
        }
        
    }
    return _alertView;
}

-(UIButton*)createSubBtnWithTitle:(NSString*)title topY:(CGFloat)topY actionMethod:(SEL)actionMethod haveBottomLine:(BOOL)haveBottomLine
{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, topY, self.frame.size.width, 55);
    [button addTarget:self action:actionMethod forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor whiteColor]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17];
    [_alertView addSubview:button];
    
    if (haveBottomLine) {
        UIImageView * line = [[UIImageView alloc]initWithFrame:CGRectMake(0, button.frame.size.height - ONE_PIXEL, button.frame.size.width, ONE_PIXEL)];
        line.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        [button addSubview:line];
    }
    
    return button;
}

#pragma mark - 识别二维码

/**
 是否包含二维码

 @return 二维码内容
 */
-(NSString*)isHaveQrCode
{
    if (_targetImage) {
        
        CIDetector * detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
        NSArray * features = [detector featuresInImage:[CIImage imageWithCGImage:_targetImage.CGImage]];
        if ([features count] > 0) {
            CIQRCodeFeature * feature = [features objectAtIndex:0];
            NSString * result = feature.messageString;
            
            if ([result length] > 0) {
                return result;
            }else{
                return @"";
            }
        }else{
            return @"";
        }
    }else{
        return @"";
    }
}

-(void)checkQrCode
{
    [self hideAnimate];
    
    if (self.checkQrCodeAction) {
        self.checkQrCodeAction(_qrCodeContent);
    }
}

#pragma mark - 加载菊花

-(BKPhotoBrowserIndicator*)browserIndicator
{
    if (!_browserIndicator) {
        _browserIndicator = [[BKPhotoBrowserIndicator alloc] initWithFrame:self.bounds];
        _browserIndicator.progressTitle = @"";
    }
    return _browserIndicator;
}

-(void)showIndicator
{
    if (_browserIndicator) {
        [self hideIndicator];
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.browserIndicator];
    [_browserIndicator startAnimation];
}

-(void)hideIndicator
{
    [_browserIndicator stopAnimation];
}

#pragma mark - 保存图片

/**
 保存图片
 */
- (void)saveImage
{
    [self showIndicator];
    
    [self checkAllowVisitPhotoAlbumHandler:^(BOOL handleFlag) {
        if (handleFlag) {
            
            __block NSString *assetId = nil;
            // 存储图片到"相机胶卷"
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                assetId = [PHAssetCreationRequest creationRequestForAssetFromImage:self.targetImage].placeholderForCreatedAsset.localIdentifier;
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideIndicator];
                        [self showRemind:@"图片保存失败"];
                    });
                    return;
                }
                
                // 把相机胶卷图片保存到自己创建的相册中
                PHAssetCollection *collection = [self collection];
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                    
                    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                    [request addAssets:@[asset]];
                    
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self hideIndicator];
                        
                        if (error) {
                            [self showRemind:@"图片保存失败"];
                            return;
                        }
                        
                        [self showRemind:@"保存成功"];
                    });
                }];
            }];
            
        }
    }];
}

/**
 检测是否允许调用相册
 
 @param handler 检测结果
 */
-(void)checkAllowVisitPhotoAlbumHandler:(void (^)(BOOL handleFlag))handler
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString * app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status) {
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    if (handler) {
                        handler(YES);
                    }
                }else{
                    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"%@没有权限访问您的相册\n在“设置-隐私-照片”中开启即可查看",app_Name] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction * ok = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        if (handler) {
                            handler(NO);
                        }
                    }];
                    [alert addAction:ok];
                    [[self locationVC] presentViewController:alert animated:YES completion:nil];
                }
            }];
        }
            break;
        case PHAuthorizationStatusRestricted:
        {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"%@没有访问相册的权限",app_Name] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (handler) {
                    handler(NO);
                }
            }];
            [alert addAction:ok];
            [[self locationVC] presentViewController:alert animated:YES completion:nil];
        }
            break;
        case PHAuthorizationStatusDenied:
        {
            UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"%@没有权限访问您的相册\n在“设置-隐私-照片”中开启即可查看",app_Name] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * ok = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (handler) {
                    handler(NO);
                }
            }];
            [alert addAction:ok];
            [[self locationVC] presentViewController:alert animated:YES completion:nil];
        }
            break;
        case PHAuthorizationStatusAuthorized:
        {
            if (handler) {
                handler(YES);
            }
        }
            break;
        default:
            break;
    }
}

/**
 获取保存图片相册
 
 @return 保存图片相册
 */
- (PHAssetCollection *)collection
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString * app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    
    // 先获得之前创建过的相册
    PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collectionResult) {
        if ([collection.localizedTitle isEqualToString:app_Name]) {
            return collection;
        }
    }
    
    // 如果相册不存在,就创建新的相册(文件夹)
    __block NSString *collectionId = nil; // __block修改block外部的变量的值
    // 这个方法会在相册创建完毕后才会返回
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // 新建一个PHAssertCollectionChangeRequest对象, 用来创建一个新的相册
        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:app_Name].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];
    
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
}

#pragma mark - 提示文本

/**
 提示
 
 @param text 文本
 */
-(void)showRemind:(NSString*)text
{
    UIWindow * window = [[[UIApplication sharedApplication] delegate] window];
    
    UIView * bgView = [[UIView alloc]init];
    bgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    bgView.layer.cornerRadius = 8.0f;
    bgView.clipsToBounds = YES;
    [window addSubview:bgView];
    
    UILabel * remindLab = [[UILabel alloc]init];
    remindLab.textColor = [UIColor whiteColor];
    CGFloat fontSize = 13.0 * window.bounds.size.width/320.0f;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    remindLab.font = font;
    remindLab.textAlignment = NSTextAlignmentCenter;
    remindLab.numberOfLines = 0;
    remindLab.backgroundColor = [UIColor clearColor];
    remindLab.text = text;
    [bgView addSubview:remindLab];
    
    CGFloat width = [self sizeWithString:text UIHeight:window.bounds.size.height font:font].width;
    if (width > window.bounds.size.width/4.0*3.0f) {
        width = window.bounds.size.width/4.0*3.0f;
    }
    CGFloat height = [self sizeWithString:text UIWidth:width font:font].height;
    
    bgView.bounds = CGRectMake(0, 0, width+30, height+30);
    bgView.layer.position = CGPointMake(window.bounds.size.width/2.0f, window.bounds.size.height/2.0f);
    
    remindLab.bounds = CGRectMake(0, 0, width, height);
    remindLab.layer.position = CGPointMake(bgView.bounds.size.width/2.0f, bgView.bounds.size.height/2.0f);
    
    [UIView animateWithDuration:1 delay:1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        bgView.alpha = 0;
    } completion:^(BOOL finished) {
        [bgView removeFromSuperview];
    }];
}

-(CGSize)sizeWithString:(NSString *)string UIWidth:(CGFloat)width font:(UIFont*)font
{
    CGRect rect = [string boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                       options: NSStringDrawingUsesFontLeading  |NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName: font}
                                       context:nil];
    
    return rect.size;
}

-(CGSize)sizeWithString:(NSString *)string UIHeight:(CGFloat)height font:(UIFont*)font
{
    CGRect rect = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                       options: NSStringDrawingUsesFontLeading  |NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName:font}
                                       context:nil];
    
    return rect.size;
}

#pragma mark - 所在VC

/**
 所在VC
 
 @return VC
 */
-(UIViewController *)locationVC
{
    UIViewController *rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;
    
    UIViewController *parent = rootVC;
    
    while ((parent = rootVC.presentedViewController) != nil ) {
        rootVC = parent;
    }
    
    while ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = [(UINavigationController *)rootVC topViewController];
    }
    
    return rootVC;
}

@end
