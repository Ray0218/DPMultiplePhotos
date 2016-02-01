//
//  DPNavTitleButton.h
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DPNavTitleButton : UIControl

@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) UIColor *titleColor;

- (void)turnArrow;
- (void)restoreArrow;
@end