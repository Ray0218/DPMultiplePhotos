//
//  DPSelectImgVC.m
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import "DPNavTitleButton.h"
#import "DPSelectCovView.h"
#import "DPSelectImgVC.h"
#import "DPShowDetailVC.h"

#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>

/**
 *  第一个相机的Cell
 */
@interface DPCameraCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *cameraImage;

@end

#define ORIGINAL_MAX_WIDTH 640.0f

@implementation DPCameraCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:202 / 255.0 green:203 / 255.0 blue:204 / 255.0 alpha:1];
        [self.contentView addSubview:self.cameraImage];

        [_cameraImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView);
            make.centerX.equalTo(self.contentView);
            make.width.mas_equalTo(100);
            make.height.mas_equalTo(100);

        }];
    }
    return self;
}

- (UIImageView *)cameraImage {    //UIViewContentModeScaleAspectFit  UIViewContentModeCenter

    if (_cameraImage == nil) {
        _cameraImage = [[UIImageView alloc] init];
        _cameraImage.image = [UIImage imageNamed:@"拍摄照片_03.png"];
        _cameraImage.contentMode = UIViewContentModeScaleAspectFit;
        //        _cameraImage.backgroundColor = [UIColor greenColor];
    }

    return _cameraImage;
}

@end

@interface DPCollectionCell : UICollectionViewCell

/**
 * 选择标记View
 */
@property (nonatomic, strong) DPSelectCovView *selectView;

@property (nonatomic, strong) ALAsset *asset;

@end

@implementation DPCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.selectView];
        //        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

- (void)setAsset:(ALAsset *)asset {
    _asset = asset;

    self.selectView.asset = asset;
}

- (DPSelectCovView *)selectView {
    if (_selectView == nil) {
        _selectView = [[DPSelectCovView alloc] initWithFrame:self.bounds];
    }

    return _selectView;
}

@end

@interface DPSelectImgVC () <UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

    {
    UICollectionView *_collectionView;

    NSInteger _currentIndex;    //默认第几行
}
@property (nonatomic, strong) NSMutableArray *assets;

@property (nonatomic, strong) NSMutableSet *selectedIndexSet;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *topCancelBtn;
@property (nonatomic, strong) DPNavTitleButton *titleButton;    //彩种标题
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) UIButton *sureButton;
@property (nonatomic, strong) UIButton *showButton;

@end
static NSString *const kCellIdentifier = @"Cell";
static NSString *const kCameraCellIdentifier = @"CameraCellIdentifier";
@implementation DPSelectImgVC

- (instancetype)init {
    self = [super init];
    if (self) {
        self.assets = [NSMutableArray array];
        _currentIndex = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.selectedIndexSet = [[NSMutableSet alloc] init];
    self.view.backgroundColor = [UIColor grayColor];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((CGRectGetWidth(self.view.frame) - 20) / 3.0, (CGRectGetWidth(self.view.frame) - 20) / 3.0);

    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 0, 5);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[DPCollectionCell class] forCellWithReuseIdentifier:kCellIdentifier];
    [_collectionView registerClass:[DPCameraCell class] forCellWithReuseIdentifier:kCameraCellIdentifier];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsMake(0, 0, 5, 0));
    }];

    self.tabBarController.tabBar.hidden = YES;

    self.titleButton.titleText = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    ;
    self.navigationItem.titleView = self.titleButton;

    self.topCancelBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    self.topCancelBtn.frame = CGRectMake(0, 0, 45, 30);
    [self.topCancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    [self.topCancelBtn setTitle:@"取消" forState:(UIControlStateNormal)];
    [self.topCancelBtn addTarget:self action:@selector(cancel:) forControlEvents:(UIControlEventTouchUpInside)];

    UIBarButtonItem *fixItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixItem.width = 45;
    UIBarButtonItem *topCancelItem = [[UIBarButtonItem alloc] initWithCustomView:self.topCancelBtn];
    self.navigationItem.rightBarButtonItem = topCancelItem;

    [self.view addSubview:self.tableView];
    self.tableView.hidden = YES;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];

    [self buildBottomLayout];
}

//- (UIImage *)dp_imageWithColor:(UIColor *)color {
//    CGRect rect = CGRectMake(0, 0, 1, 1);
//    UIGraphicsBeginImageContext(rect.size);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    CGContextSetFillColorWithColor(context, [color CGColor]);
//    CGContextFillRect(context, rect);
//
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    return image;
//}

#pragma mark - 创建底部
- (void)buildBottomLayout {
    self.showButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.showButton setTitle:@"预览" forState:UIControlStateNormal];
    [self.showButton addTarget:self action:@selector(pvt_showDetail) forControlEvents:UIControlEventTouchUpInside];
    self.showButton.titleLabel.font = [UIFont systemFontOfSize:16];
    //改变文字颜色
    [self.showButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.showButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];

    //    改变背景颜色
    //    [self.showButton setBackgroundImage:[self dp_imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    //    [self.showButton setBackgroundImage:[self dp_imageWithColor:[UIColor greenColor]] forState:UIControlStateDisabled];

    [self.bottomView addSubview:self.showButton];
    self.showButton.enabled = NO;

    [self.showButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).offset(15);
        make.centerY.equalTo(self.bottomView);

    }];

    self.sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sureButton.backgroundColor = [UIColor clearColor];
    [self.sureButton setTitle:@"完成()" forState:UIControlStateNormal];
    [self.sureButton setBackgroundImage:[UIImage imageNamed:@"加关注-ios"] forState:UIControlStateNormal];
    self.sureButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.sureButton setTitleColor:[UIColor redColor] forState:(UIControlStateNormal)];
    [self.sureButton addTarget:self action:@selector(pvt_done:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.sureButton];

    [self.sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).offset(-5);
        make.centerY.equalTo(self.bottomView);
        make.width.mas_equalTo(67.5);
        make.height.mas_equalTo(30);

    }];

    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.bottom.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
}

#pragma mark - getter/setter

- (UIView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    }
    return _bottomView;
}
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    }

    return _tableView;
}

//图片标题
- (DPNavTitleButton *)titleButton {
    if (_titleButton == nil) {
        _titleButton = [[DPNavTitleButton alloc]
            initWithFrame:CGRectMake(0, 0, 110, 44)];
        _titleButton.titleColor = [UIColor blackColor];
        [_titleButton addTarget:self action:@selector(pvt_onExpandNav:) forControlEvents:UIControlEventTouchUpInside];
        _titleButton.selected = NO;
    }
    return _titleButton;
}

#pragma mark - 点击事件
//点击图片展开图片类型
- (void)pvt_onExpandNav:(UIControl *)control {
    control.selected = !control.selected;
    self.tableView.hidden = !control.selected;
}
- (void)setUpDetailAddedImageView:(NSArray *)images {
    //    if (self.selectFinishHandle) {
    //        self.selectFinishHandle(NO, NO, images);
    //    }
    //    [self dismissViewControllerAnimated:YES completion:nil];
    //
}
- (void)pvt_showDetail {
    DPShowDetailVC *browser = [[DPShowDetailVC alloc] init];

    browser.assetArray = [self.selectedIndexSet allObjects];

    __weak typeof(self) weakSelf = self;
    browser.selectBlock = ^(ALAsset *curAssert, BOOL isSelect) {

        if (isSelect && ![weakSelf isHaveTheAsset:curAssert]) {
            [weakSelf.selectedIndexSet addObject:curAssert];
        } else if (!isSelect && [weakSelf isHaveTheAsset:curAssert]) {
            [weakSelf removeAssetWithAsset:curAssert];
        }

    };

    browser.finishBlock = ^(NSArray<ALAsset *> *assetArray) {

        if (weakSelf.selectFinishHandle) {
            weakSelf.selectFinishHandle(NO, NO, assetArray);
        }
        [weakSelf dismissViewControllerAnimated:YES completion:nil];

    };

    browser.currentIndex = 0;
    [self.navigationController pushViewController:browser animated:YES];
}

- (void)cancel:(id)sender {
    if (!self.tableView.hidden) {
        self.titleButton.selected = NO;
        self.tableView.hidden = YES;
        return;
    }

    [self dismissViewControllerAnimated:YES completion:^{

    }];
    if (self.selectFinishHandle) {
        self.selectFinishHandle(YES, NO, nil);
    }
}

#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.assertsGroupArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentify = @"cellIdentify";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor =
            cell.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.65];
    }

    ALAssetsGroup *groupAsser = (ALAssetsGroup *)self.assertsGroupArray[indexPath.row];
    [groupAsser setAssetsFilter:[ALAssetsFilter allPhotos]];

    NSString *assertName = [groupAsser valueForProperty:ALAssetsGroupPropertyName];
    NSInteger count = [groupAsser numberOfAssets];
    cell.textLabel.text = [NSString stringWithFormat:@"%@(%zd)", assertName, count];
    cell.imageView.image = [UIImage imageWithCGImage:groupAsser.posterImage];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.titleButton.selected = NO;
    [self.tableView reloadData];
    tableView.hidden = YES;
    _currentIndex = indexPath.row;
    self.assetsGroup = _assertsGroupArray[_currentIndex];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        NSLog(@"%.1f", [[[UIDevice currentDevice] systemVersion] floatValue]);
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
    }
}

#pragma mark -点击完成
- (void)topImageBtnClick:(UIButton *)button {
    button.selected = !button.selected;
}
- (void)pvt_done:(id)sender {
    if (self.selectFinishHandle) {
        self.selectFinishHandle(NO, NO, [self.selectedIndexSet allObjects]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assets.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        DPCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCameraCellIdentifier forIndexPath:indexPath];

        return cell;
    }

    DPCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellIdentifier forIndexPath:indexPath];

    cell.selectView.overlayView.hidden = NO;

    ALAsset *curAsset = [self.assets objectAtIndex:indexPath.row - 1];
    cell.asset = curAsset;

    cell.selectView.isSelected = curAsset.isSelected;

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted) {
                [[[UIAlertView alloc] initWithTitle:nil message:@"本应用无访问相机的权限，如需访问，可在设置中修改" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil] show];
                return;
            }
        } else {
            ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
            if (author == kCLAuthorizationStatusRestricted || author == kCLAuthorizationStatusDenied) {
                [[[UIAlertView alloc] initWithTitle:nil message:@"本应用无访问相机的权限，如需访问，可在设置中修改" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil, nil] show];
                return;
            }
        }

        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.delegate = self;
            [self presentViewController:imagePicker animated:YES completion:^{

            }];
        }

        return;
    }

    DPCollectionCell *cell = (DPCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];

    ALAsset *curAsset = [self.assets objectAtIndex:indexPath.row - 1];

    if ([self isHaveTheAsset:curAsset]) {
        [self removeAssetWithAsset:curAsset];

        cell.selectView.isSelected = NO;
        curAsset.isSelected = NO;
        [self.sureButton setTitle:[NSString stringWithFormat:@"完成(%zd)", self.selectedIndexSet.count] forState:UIControlStateNormal];
        self.showButton.enabled = self.selectedIndexSet.count;

    } else {
        [ALAsset getorignalImage:curAsset completion:^(UIImage *image) {

            NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
            NSInteger length = imageData.length;

            [self.selectedIndexSet addObject:curAsset];
            cell.selectView.isSelected = YES;
            curAsset.isSelected = YES;

            [self.sureButton setTitle:[NSString stringWithFormat:@"完成(%zd)", self.selectedIndexSet.count] forState:UIControlStateNormal];
            self.showButton.enabled = self.selectedIndexSet.count;

            NSLog(@"图片按0.8压缩后的大小%.2f", length / (1024.0 * 1024.0));
        }];
    }
}

- (BOOL)isHaveTheAsset:(ALAsset *)asset {
    for (ALAsset *theAsset in self.selectedIndexSet) {
        if ([asset.defaultRepresentation.url isEqual:theAsset.defaultRepresentation.url]) {
            return YES;
        }
    }

    return NO;
}
- (void)removeAssetWithAsset:(ALAsset *)asset {
    ALAsset *theAsset;
    for (ALAsset *curAsset in self.selectedIndexSet) {
        if ([curAsset.defaultRepresentation.url isEqual:asset.defaultRepresentation.url]) {
            theAsset = curAsset;
            break;
        }
    }

    if (theAsset) {
        [self.selectedIndexSet removeObject:theAsset];
    }
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *selectImage = [info valueForKey:@"UIImagePickerControllerOriginalImage"];

        UIImage *tempImage = nil;
        if (selectImage.imageOrientation != UIImageOrientationUp) {
            UIGraphicsBeginImageContext(selectImage.size);
            [selectImage drawInRect:CGRectMake(0, 0, selectImage.size.width, selectImage.size.height)];
            tempImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        } else {
            tempImage = selectImage;
        }

        if (self.selectFinishHandle) {
            self.selectFinishHandle(NO, YES, @[ tempImage ]);
        }
        [self dismissViewControllerAnimated:YES completion:nil];

    }];
}

#pragma mark image scale utility
- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
    if (sourceImage.size.width < ORIGINAL_MAX_WIDTH) return sourceImage;
    CGFloat btWidth = 0.0f;
    CGFloat btHeight = 0.0f;
    if (sourceImage.size.width > sourceImage.size.height) {
        btHeight = ORIGINAL_MAX_WIDTH;
        btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height);
    } else {
        btWidth = ORIGINAL_MAX_WIDTH;
        btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width);
    }
    CGSize targetSize = CGSizeMake(btWidth, btHeight);
    return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}
- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;

        if (widthFactor > heightFactor)
            scaleFactor = widthFactor;    // scale to fit height
        else
            scaleFactor = heightFactor;    // scale to fit width
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;

        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    UIGraphicsBeginImageContext(targetSize);    // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;

    [sourceImage drawInRect:thumbnailRect];

    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) NSLog(@"could not scale image");

    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - 传输数据

- (void)setAssertsGroupArray:(NSArray *)assertsGroupArray {
    _assertsGroupArray = assertsGroupArray;
    if (assertsGroupArray.count > _currentIndex) {
        self.assetsGroup = _assertsGroupArray[_currentIndex];
    } else {
        [self.assets removeAllObjects];
    }
}
- (void)setAssetsGroup:(ALAssetsGroup *)assetsGroup {
    _assetsGroup = assetsGroup;

    [self.assets removeAllObjects];
    // Set title
    self.titleButton.titleText = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    ;

    // Set assets filter
    [self.assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];

    // Load assets

    [self.assetsGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            NSString *type = [result valueForProperty:ALAssetPropertyType];

            if ([type isEqualToString:ALAssetTypePhoto]) {
                if ([self isHaveTheAsset:result]) {
                    result.isSelected = YES;
                } else {
                    result.isSelected = NO;
                }

                [self.assets addObject:result];
            }
        }
    }];

    [_collectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"DEMOFirstViewController will appear");

    [_collectionView reloadData];
    [self.sureButton setTitle:[NSString stringWithFormat:@"完成(%zd)", self.selectedIndexSet.count] forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"DEMOFirstViewController will disappear");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
