//
//  DPShowDetailVC.m
//  DPMultiplePhotos
//
//  Created by Ray on 16/2/1.
//  Copyright © 2016年 Ray. All rights reserved.
//

#import "DPShowDetailVC.h"
#import "Masonry.h"

@interface DPZoomScrollView : UIScrollView <UIScrollViewDelegate> {
    UIImageView *_imageView;
}

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation DPZoomScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.imageView];
        self.delegate = self;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.minimumZoomScale = 0.5;
        self.maximumZoomScale = 3;
    }
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"######## DPZoomScrollView #########");
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

//让图片居中
- (void)scrollViewDidZoom:(UIScrollView *)aScrollView {
    CGFloat offsetX = (aScrollView.bounds.size.width > aScrollView.contentSize.width) ? (aScrollView.bounds.size.width - aScrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (aScrollView.bounds.size.height > aScrollView.contentSize.height) ? (aScrollView.bounds.size.height - aScrollView.contentSize.height) * 0.5 : 0.0;
    self.imageView.center = CGPointMake(aScrollView.contentSize.width * 0.5 + offsetX,
                                        aScrollView.contentSize.height * 0.5 + offsetY);
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor clearColor];

        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = YES;
    }
    return _imageView;
}

@end

static NSString *const reuseIdentifier = @"browserCell";

//collectionCell
@interface DPImgShowCollectionCell : UICollectionViewCell

@property (nonatomic, strong) DPZoomScrollView *imageScrollView;

@end

@implementation DPImgShowCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageScrollView];
    }
    return self;
}

- (DPZoomScrollView *)imageScrollView {
    if (_imageScrollView == nil) {
        _imageScrollView = [[DPZoomScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([[UIScreen mainScreen] bounds]), CGRectGetHeight(self.frame))];
    }
    return _imageScrollView;
}
//- (UIImageView *)imgView {
//    if (_imgView == nil) {
//        _imgView = [[UIImageView alloc] init];
//        _imgView.contentMode = UIViewContentModeScaleAspectFit;
//        _imgView.userInteractionEnabled = YES;
//    }
//    return _imgView;
//}
@end

@interface DPShowDetailVC () <UICollectionViewDelegate, UICollectionViewDataSource> {
    UICollectionView *_collectionView;
    NSInteger _selectCount;
}

@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UIButton *confrimButton;
@property (nonatomic, strong) UIButton *selectButton;

@end

@implementation DPShowDetailVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}
- (void)viewDidLoad {
    self.view.backgroundColor = [UIColor whiteColor];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self createCollectionView];
    [self createTopView];
    [self createBottomView];
}

- (void)createCollectionView {
    //flowLayout
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight(self.view.frame) - 20);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];

    _collectionView.collectionViewLayout = flowLayout;
    _collectionView.pagingEnabled = YES;
    _collectionView.showsHorizontalScrollIndicator = NO;
    [_collectionView registerClass:[DPImgShowCollectionCell class] forCellWithReuseIdentifier:reuseIdentifier];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.delegate = self;
    _collectionView.bounces = NO;
    _collectionView.dataSource = self;
    [self.view addSubview:_collectionView];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).offset(20);
            make.left.and.right.and.bottom.equalTo(self.view);
        }];
    } else {
        [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.insets(UIEdgeInsetsZero);
        }];
    }
}

- (void)createTopView {
    UIView *backView = [[UIView alloc] init];

    backView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    backView.userInteractionEnabled = YES;
    [self.view addSubview:backView];
    CGFloat offDev = 0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        offDev = 20;
    }

    [backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.and.right.equalTo(self.view);
        make.height.mas_equalTo(44 + offDev);
    }];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setTitle:@"..." forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(pvt_back) forControlEvents:UIControlEventTouchUpInside];
    [backView addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(backView).offset(offDev / 2);
        make.left.equalTo(backView).offset(20);
        make.width.and.height.mas_equalTo(20);
    }];

    [backView addSubview:self.selectButton];
    [self.selectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(backView).offset(offDev / 2);
        make.right.equalTo(backView).offset(-10);
        make.height.mas_equalTo(25);
        make.width.mas_equalTo(60);
    }];

    [backView addSubview:self.indexLabel];
    [self.indexLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(backView);
        make.centerY.equalTo(backView).offset(offDev / 2);
        make.height.mas_equalTo(25);
    }];
}

- (void)createBottomView {
    UIView *backView = [[UIView alloc] init];
    backView.backgroundColor = [UIColor clearColor];
    backView.userInteractionEnabled = YES;
    [self.view addSubview:backView];
    [backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.left.and.right.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];

    [backView addSubview:self.confrimButton];
    [self.confrimButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(backView).offset(-10);
        //        make.bottom.equalTo(backView).offset(-5);
        make.centerY.equalTo(backView);
        make.width.mas_equalTo(67.5);
        make.height.mas_equalTo(30);
    }];
}

- (void)pvt_back {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark -

- (UILabel *)indexLabel {
    if (_indexLabel == nil) {
        //添加index标签
        _indexLabel = [[UILabel alloc] init];
        _indexLabel.textAlignment = NSTextAlignmentCenter;
        _indexLabel.font = [UIFont systemFontOfSize:18.0];
        _indexLabel.textColor = [UIColor whiteColor];
        _indexLabel.userInteractionEnabled = YES;
    }
    return _indexLabel;
}

- (UIButton *)selectButton {
    if (_selectButton == nil) {
        _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectButton setTitle:@"勾选" forState:(UIControlStateNormal)];
        [_selectButton setTitle:@"取消" forState:(UIControlStateSelected)];

        [_selectButton addTarget:self action:@selector(pvt_selected:) forControlEvents:UIControlEventTouchUpInside];
    }

    return _selectButton;
}

- (UIButton *)confrimButton {
    if (_confrimButton == nil) {
        _confrimButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confrimButton.backgroundColor = [UIColor clearColor];
        [_confrimButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _confrimButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_confrimButton setTitle:@"完成" forState:UIControlStateNormal];
        [_confrimButton addTarget:self action:@selector(pvt_confirm) forControlEvents:UIControlEventTouchUpInside];
    }

    return _confrimButton;
}

#pragma mark - 响应事件

- (void)pvt_selected:(UIButton *)btn {
    ALAsset *CurAsset = self.assetArray[self.currentIndex];
    CurAsset.isSelected = !CurAsset.isSelected;

    __weak typeof(self) weakSelf = self;
    [ALAsset getorignalImage:CurAsset completion:^(UIImage *image) {

        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSInteger length = imageData.length;

        if (imageData.length / (1024.0 * 1024.0) > 5.0) {
            //            [[DPToast makeText:@"图片大于5M"] showWithOffset:SCREEN_HEIGHT / 2 - 40];

        } else {
            btn.selected = !btn.selected;

            _selectCount += btn.selected ? 1 : (-1);

            if (weakSelf.selectBlock) {
                weakSelf.selectBlock([self.assetArray objectAtIndex:weakSelf.currentIndex], btn.selected);
            }
            [weakSelf.confrimButton setTitle:[NSString stringWithFormat:@"完成(%zd)", _selectCount] forState:UIControlStateNormal];
        }

        NSLog(@"图片按0.8压缩后的大小%.2f", length / (1024.0 * 1024.0));
    }];
}

- (void)pvt_confirm {
    if (self.finishBlock) {
        self.finishBlock(self.assetArray);
    }
}

- (void)setAssetArray:(NSArray *)assetArray {
    _assetArray = assetArray;
    [self.confrimButton setTitle:[NSString stringWithFormat:@"完成(%zd)", assetArray.count] forState:UIControlStateNormal];
    _selectCount = assetArray.count;
}
- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    self.indexLabel.text = [NSString stringWithFormat:@"%ld/%ld", self.currentIndex + 1, self.assetArray.count];

    ALAsset *model = [self.assetArray objectAtIndex:currentIndex];
    self.selectButton.selected = model.isSelected;
}

#pragma mark -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DPImgShowCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor blackColor];
    ALAsset *model = self.assetArray[indexPath.item];
    [ALAsset getorignalImage:model completion:^(UIImage *image) {
        cell.imageScrollView.imageView.image = image;
        CGFloat scale = image.size.height / image.size.width;

        CGRect frame = CGRectMake(0, 0, CGRectGetWidth(cell.imageScrollView.bounds), 0);
        frame.size.height = MIN(scale * CGRectGetWidth(cell.imageScrollView.bounds), CGRectGetHeight(cell.imageScrollView.bounds));
        cell.imageScrollView.imageView.frame = frame;
        cell.imageScrollView.imageView.center = cell.imageScrollView.center;
        cell.imageScrollView.contentSize = cell.imageScrollView.imageView.frame.size;

    }];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    DPImgShowCollectionCell *curCell = (DPImgShowCollectionCell *)cell;
    [curCell.imageScrollView setZoomScale:1.0 animated:NO];
    [curCell.imageScrollView setNeedsLayout];
    [curCell.imageScrollView layoutIfNeeded];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger index = (scrollView.contentOffset.x + scrollView.bounds.size.width * 0.5) / scrollView.bounds.size.width;
    if (index < 0)
        return;

    if (self.currentIndex != index)
        self.currentIndex = index;
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
