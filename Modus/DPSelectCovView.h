//
//  DPSelectCovView.h
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AssetsLibrary/AssetsLibrary.h>

/**
 *  对号图标
 */
@interface DPMarkView : UIView

/**
 *  是否被选中
 */
@property (assign, nonatomic) BOOL isSelected;

@end

//带有选择图片的覆盖层
@interface DPCoverView : UIView

/**
 *  对号图标
 */
@property (nonatomic, strong) DPMarkView *checkmarkView;

@end

@interface DPSelectCovView : UIView

@property (nonatomic, strong) ALAsset *asset;
/**
 *  标记选中状态的View
 */
@property (nonatomic, strong, readonly) DPCoverView *overlayView;
/**
 *  是否被选中
 */
@property (nonatomic) BOOL isSelected;

@end
