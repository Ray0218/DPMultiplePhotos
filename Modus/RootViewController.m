//
//  RootViewController.m
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import "RootViewController.h"

#import "DPComAddedImgView.h"
#import "DPSelectImgVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

@interface RootViewController () <UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSMutableArray *originImages;

@property (strong, nonatomic) DPComAddedImgView *addedImageView;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

@end

@implementation RootViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"图片选择";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.originImages = [NSMutableArray array];
    [self setUpAddedImageView:nil];
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"添加" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pvtBtn) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor blueColor];
    btn.frame = CGRectMake(20, 250, 200, 30);
    [self.view addSubview:btn];
}
- (void)datePickerValueChanged:(UIDatePicker *)picker {
}

- (void)pvtBtn {
    if (self.originImages.count >= kMaxCount) {
        [[[UIAlertView alloc] initWithTitle:@"Sorry 抱歉" message:@"图片最多只能选kMaxCount张" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }
    [self setUpPicker];
}

- (void)creatAddImageViewWithImages:(NSArray *)images {
    __weak typeof(self) weakSelf = self;
    self.addedImageView = [[DPComAddedImgView alloc] initWithUIImages:nil screenWidth:CGRectGetWidth([[UIScreen mainScreen] bounds])];
    self.addedImageView.backgroundColor = [UIColor grayColor];
    self.addedImageView.frame = CGRectMake(0, 80, CGRectGetWidth([[UIScreen mainScreen] bounds]), (CGRectGetWidth([[UIScreen mainScreen] bounds]) - 25) / 4.0 + 10);

    [self.addedImageView setPickerAction:^{
        [weakSelf setUpPicker];
    }];
    self.addedImageView.imagesChangeFinish = ^() {

    };
    self.addedImageView.imagesDeleteFinish = ^(NSInteger index) {
        [weakSelf.originImages removeObjectAtIndex:index];
    };
    [self.addedImageView addImages:images];
    self.addedImageView.actionWithTapImages = ^() {

    };
    [self.view addSubview:self.addedImageView];
}

- (void)setUpPicker {
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == kCLAuthorizationStatusRestricted || author == kCLAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"本应用无访问照片的权限，如需访问，可在设置中修改" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil] show];
        return;
    }
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] &&
         [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])) {
        __weak typeof(self) weakSelf = self;
        [self loadAssetsGroup:^(NSArray *assetsGroups) {

            DPSelectImgVC *imagePickerController = [[DPSelectImgVC alloc] init];
            imagePickerController.assertsGroupArray = assetsGroups;

            [imagePickerController setSelectFinishHandle:^(BOOL isCanceled, BOOL isCamera, NSArray *assets) {
                if (!isCanceled) {
                    if (!isCamera) {
                        [weakSelf dealWithAssets:assets];
                    } else {
                        if (assets) {
                            [weakSelf.originImages addObject:[assets lastObject]];
                            [weakSelf setUpAddedImageView:assets];
                        }
                    }
                }
            }];

            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imagePickerController];

            [weakSelf presentViewController:navigationController animated:YES completion:NULL];

        }];
    }
}

- (void)dealWithAssets:(NSArray *)assets {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableArray *array = [NSMutableArray array];
        for (ALAsset *asset in assets) {
            UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
            if (image) {
                [array addObject:image];
            }
            if ([asset defaultRepresentation]) {
                //这里把图片压缩成fullScreenImage分辨率上传，可以修改为fullResolutionImage使用原图上传
                UIImage *originImage = [UIImage
                    imageWithCGImage:[asset.defaultRepresentation fullScreenImage]
                               scale:[asset.defaultRepresentation scale]
                         orientation:UIImageOrientationUp];
                if (originImage) {
                    [self.originImages addObject:originImage];
                }
            } else {
                UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
                image = [self compressImage:image];
                if (image) {
                    [self.originImages addObject:image];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setUpAddedImageView:array];
        });
    });
}
- (UIImage *)compressImage:(UIImage *)image {
    UIImage *resultImage = image;
    if (resultImage.CGImage) {
        NSData *tempImageData = UIImageJPEGRepresentation(resultImage, 0.9);
        if (tempImageData) {
            resultImage = [UIImage imageWithData:tempImageData];
        }
    }
    return image;
}

- (void)setUpAddedImageView:(NSArray *)images {
    if (!self.addedImageView) {
        [self creatAddImageViewWithImages:images];
    } else {
        [self.addedImageView setScreemWidth:CGRectGetWidth([[UIScreen mainScreen] bounds])];
        [self.addedImageView addImages:images];
    }

    self.addedImageView.contentSize = CGSizeMake(CGRectGetWidth([[UIScreen mainScreen] bounds]), self.addedImageView.contentSize.height);
    self.addedImageView.hidden = NO;
}

#pragma mark - 获取相册数据
- (void)loadAssetsGroup:(void (^)(NSArray *assetsGroups))completion {
    NSArray *groupTypes = @[ @(ALAssetsGroupSavedPhotos),
                             @(ALAssetsGroupPhotoStream),
                             @(ALAssetsGroupAlbum) ];

    __block NSMutableArray *assetsGroups = [NSMutableArray array];
    __block NSUInteger numberOfFinishedTypes = 0;

    for (NSNumber *type in groupTypes) {
        [self.assetsLibrary enumerateGroupsWithTypes:[type unsignedIntegerValue]
            usingBlock:^(ALAssetsGroup *assetsGroup, BOOL *stop) {
                if (assetsGroup) {
                    // Filter the assets group
                    [assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];

                    if (assetsGroup.numberOfAssets > 0) {
                        // Add assets group
                        [assetsGroups addObject:assetsGroup];
                    }
                } else {
                    numberOfFinishedTypes++;
                }

                // Check if the loading finished
                if (numberOfFinishedTypes == groupTypes.count) {
                    // Sort assets groups
                    NSArray *sortedAssetsGroups = [self sortAssetsGroups:(NSArray *)assetsGroups typesOrder:groupTypes];

                    // Call completion block
                    if (completion) {
                        completion(sortedAssetsGroups);
                    }
                }
            }
            failureBlock:^(NSError *error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }];
    }
}

#pragma mark - 对相册进行排序
- (NSArray *)sortAssetsGroups:(NSArray *)assetsGroups typesOrder:(NSArray *)typesOrder {
    NSMutableArray *sortedAssetsGroups = [NSMutableArray array];

    for (ALAssetsGroup *assetsGroup in assetsGroups) {
        if (sortedAssetsGroups.count == 0) {
            [sortedAssetsGroups addObject:assetsGroup];
            continue;
        }

        ALAssetsGroupType assetsGroupType = [[assetsGroup valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue];
        NSUInteger indexOfAssetsGroupType = [typesOrder indexOfObject:@(assetsGroupType)];

        for (NSInteger i = 0; i <= sortedAssetsGroups.count; i++) {
            if (i == sortedAssetsGroups.count) {
                [sortedAssetsGroups addObject:assetsGroup];
                break;
            }

            ALAssetsGroup *sortedAssetsGroup = sortedAssetsGroups[i];
            ALAssetsGroupType sortedAssetsGroupType = [[sortedAssetsGroup valueForProperty:ALAssetsGroupPropertyType] unsignedIntegerValue];
            NSUInteger indexOfSortedAssetsGroupType = [typesOrder indexOfObject:@(sortedAssetsGroupType)];

            if (indexOfAssetsGroupType < indexOfSortedAssetsGroupType) {
                [sortedAssetsGroups insertObject:assetsGroup atIndex:i];
                break;
            }
        }
    }

    return [sortedAssetsGroups copy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
