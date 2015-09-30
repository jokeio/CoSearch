//
//  ViewController.m
//  CoSearch
//
//  Created by Fnoz on 15/9/10.
//  Copyright (c) 2015年 Fnoz. All rights reserved.
//

#import "ViewController.h"
#import "SearchViewController.h"
#import "SearchTypeCollectionCell.h"
#import "AppDelegate.h"

static NSString *const kSearchTypeCollectionCellID = @"kSearchTypeCollectionCellID";
#define SearchFieldHeight 52.0f
#define StatusBarHeight 20.0f

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    
    UIView *wall0 = [[UIView alloc] initWithFrame:CGRectMake(0, SearchFieldHeight+StatusBarHeight, self.view.frame.size.width/3.0f, self.view.frame.size.height)];
    wall0.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [self.view addSubview:wall0];
    
    UIView *wall1 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/3.0f, SearchFieldHeight+StatusBarHeight, self.view.frame.size.width/3.0f, self.view.frame.size.height)];
    wall1.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    [self.view addSubview:wall1];
    
    UIView *wall2 = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width*2/3.0f, SearchFieldHeight+StatusBarHeight, self.view.frame.size.width/3.0f, self.view.frame.size.height)];
    wall2.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [self.view addSubview:wall2];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, StatusBarHeight, self.view.frame.size.width, SearchFieldHeight)];
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.placeholder = @"输入关键字，并点击希望的搜索引擎";
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    self.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, self.textField.frame.size.height)];
    [self.view addSubview:self.textField];
    
    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, SearchFieldHeight+StatusBarHeight, self.view.frame.size.width, self.view.frame.size.height-SearchFieldHeight-StatusBarHeight) collectionViewLayout:flowLayout];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    self.collectionView.dataSource=self;
    self.collectionView.delegate=self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.collectionView registerNib:[UINib nibWithNibName:@"SearchTypeCollectionCell" bundle:nil] forCellWithReuseIdentifier:kSearchTypeCollectionCellID];
    [self.view addSubview:self.collectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return (20/3+1)*3;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTypeCollectionCell *cell = (SearchTypeCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kSearchTypeCollectionCellID forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithWhite:0.85+indexPath.row%2*0.05 alpha:1];

    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    NSMutableArray *searchTypeArray = appDelegate.searchTypeArray;
    
    cell.searchTypeLabel.frame = CGRectMake(0, cell.frame.size.height*0.7, cell.frame.size.width, cell.frame.size.height*0.2);
    NSString *searchTypeText;
    if (indexPath.row>=searchTypeArray.count)
    {
        searchTypeText = @"空缺";
    }
    else
    {
        searchTypeText = [searchTypeArray objectAtIndex:indexPath.row];
    }
    cell.searchTypeLabel.text = searchTypeText;    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width/3.0f, self.view.frame.size.width/3.0f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

#pragma mark UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SearchViewController *searchVC = [[SearchViewController alloc] init];
    
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    NSMutableArray *searchTypeArray = appDelegate.searchTypeArray;
    NSMutableDictionary *searchTypeAndSearchStringDic = appDelegate.searchTypeAndSearchStringDic;
    
    searchVC.searchKey = self.textField.text;
    searchVC.urlFormatStr = [searchTypeAndSearchStringDic objectForKey:[searchTypeArray objectAtIndex:indexPath.row]];
    searchVC.searchTypeIndex = indexPath.row;
    [self presentViewController:searchVC animated:YES completion:nil];
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

@end