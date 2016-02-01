//
//  MenuViewController.h
//  MutilPhotos
//
//  Created by Ray on 15/12/18.
//  Copyright © 2015年 Ray. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController

@property (nonatomic, copy, readwrite) NSArray<ALAssetsGroup *> *assetsGroups;

@end
