//
//  DPSelectImgVC.h
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

/**
 *  图片选择完成
 *
 *  @param isCanceled 是否是取消
 *  @param isCamera   是否是相机
 *  @param assets     选中的数据
 */
typedef void (^UMImagePickerFinishHandle)(BOOL isCanceled, BOOL isCamera, NSArray *assets);

@interface DPSelectImgVC : UIViewController

@property (nonatomic, strong) NSArray *assertsGroupArray;
/**
 *  图片选择完成
 */
@property (nonatomic, copy) UMImagePickerFinishHandle selectFinishHandle;

@end
