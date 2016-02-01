//
//  DPShowDetailVC.h
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import "ALAsset+selectType.h"
#import <UIKit/UIKit.h>

typedef void (^DPImageSelectBlock)(ALAsset *curModel, BOOL isSelect);
typedef void (^DPFinish)(NSArray *assetArray);
@interface DPShowDetailVC : UIViewController

@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) NSArray *assetArray;

@property (nonatomic, copy) DPImageSelectBlock selectBlock;
@property (nonatomic, copy) DPFinish finishBlock;

@end
