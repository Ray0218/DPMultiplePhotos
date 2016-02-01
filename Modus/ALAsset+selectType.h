//
//  ALAsset+selectType.h
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
@interface ALAsset (selectType)

@property (nonatomic, assign) BOOL isSelected;

+ (void)getorignalImage:(ALAsset *)assert completion:(void (^)(UIImage *))returnImage;

@end