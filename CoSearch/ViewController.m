//
//  ViewController.m
//  CoSearch
//
//  Created by Fnoz on 15/9/10.
//  Copyright (c) 2015年 Fnoz. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "SearchTypeCollectionCell.h"
#import "SearchType.h"
#import "Common.h"
#import "Database.h"

static NSString *const kSearchTypeCollectionCellID = @"kSearchTypeCollectionCellID";
#define SearchFieldHeight 52.0f
#define StatusBarHeight 20.0f
#define WebViewMaskViewColor [UIColor colorWithWhite:0.98 alpha:1]

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *searchTypeBtn;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) UIView *webViewContainer;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) SearchType *currentType;
@property (nonatomic, strong) UIButton *reloadPageBtn;
@property (nonatomic, strong) UIView *inputBgView;
@property (nonatomic, strong) UIView *toolBar;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    Database *db = [Database sharedFMDBSqlite];
    appDelegate.searchTypeArray = [[db getSearchTypeInDB] copy];
    
    self.view.backgroundColor = [UIColor colorWithRed:237/255.0f green:240/255.0f blue:244/255.0f alpha:1];
    
    self.inputBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, StatusBarHeight+SearchFieldHeight)];
    self.inputBgView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    [self.view addSubview:self.inputBgView];
    
    UIView *inputAngBtnBgView = [[UIView alloc] initWithFrame:CGRectMake(10, StatusBarHeight+8, self.view.frame.size.width-20, SearchFieldHeight-16)];
    inputAngBtnBgView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    inputAngBtnBgView.layer.cornerRadius = 5.0f;
    [self.view addSubview:inputAngBtnBgView];
    
    self.searchTypeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, inputAngBtnBgView.frame.size.height, inputAngBtnBgView.frame.size.height)];
    self.searchTypeBtn.layer.cornerRadius = 5.0f;
    self.searchTypeBtn.clipsToBounds = YES;
    self.searchTypeBtn.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.searchTypeBtn.imageView.layer.cornerRadius = 10.0f;
    self.searchTypeBtn.imageView.clipsToBounds = YES;
    self.searchTypeBtn.imageView.layer.shadowColor = [UIColor clearColor].CGColor;
    [inputAngBtnBgView addSubview:self.searchTypeBtn];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger defaultSearchTypeId = [[defaults valueForKey:kSearchTypeCollectionCellID] integerValue];
    if (!defaultSearchTypeId)
    {
        defaultSearchTypeId = 0;
        [defaults setObject:@(defaultSearchTypeId) forKey:kSearchTypeCollectionCellID];
    }
    if (0!=appDelegate.searchTypeArray.count) {
        self.currentType = [appDelegate.searchTypeArray objectAtIndex:defaultSearchTypeId];
    }
    [self.searchTypeBtn setImage:[UIImage imageNamed:self.currentType.searchTypeImageName] forState:UIControlStateNormal];
    [self adjestSearchBgColor];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(inputAngBtnBgView.frame.size.height, 0, inputAngBtnBgView.frame.size.width-2*inputAngBtnBgView.frame.size.height, inputAngBtnBgView.frame.size.height)];
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.placeholder = @"输入关键字，点击搜索引擎";
    self.textField.font = [UIFont systemFontOfSize:15.0f];
    self.textField.delegate = self;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    self.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, self.textField.frame.size.height)];
    self.textField.returnKeyType = UIReturnKeySearch;
    [inputAngBtnBgView addSubview:self.textField];
        
    self.searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(inputAngBtnBgView.frame.size.width-40, 0, inputAngBtnBgView.frame.size.height, inputAngBtnBgView.frame.size.height)];
    self.searchBtn.layer.cornerRadius = 5.0f;
    [self.searchBtn setImage:[UIImage imageNamed:@"goToSearch"] forState:UIControlStateNormal];
    self.searchBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 12, 8, 4);
    [self.searchBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.searchBtn addTarget:self action:@selector(searchBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [inputAngBtnBgView addSubview:self.searchBtn];
    
    UICollectionViewFlowLayout *flowLayout=[[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(10, SearchFieldHeight+StatusBarHeight, self.view.frame.size.width-20, self.view.frame.size.height-SearchFieldHeight-StatusBarHeight) collectionViewLayout:flowLayout];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    self.collectionView.dataSource=self;
    self.collectionView.delegate=self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.collectionView registerClass:[SearchTypeCollectionCell class] forCellWithReuseIdentifier:kSearchTypeCollectionCellID];
    [self.view addSubview:self.collectionView];
    
    self.webViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-StatusBarHeight)];
    self.webViewContainer.clipsToBounds = YES;
    self.webViewContainer.hidden = YES;
    [self decorateWebViewContainer];
    [self decorateToolBar];
    [self.view addSubview:self.webViewContainer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UICollectionViewDataSource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    return appDelegate.searchTypeArray.count; //fnoztodo 暂时屏蔽添加搜索引擎
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTypeCollectionCell *cell = (SearchTypeCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kSearchTypeCollectionCellID forIndexPath:indexPath];
    
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    if (indexPath.row+2>appDelegate.searchTypeArray.count) {
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    
    NSMutableArray *searchTypeArray = appDelegate.searchTypeArray;
    NSString *searchTypeText;
    UIImage *searchTypeImage;
    if (indexPath.row<searchTypeArray.count)
    {
        searchTypeText = ((SearchType *)[searchTypeArray objectAtIndex:indexPath.row]).searchTypeName;
        searchTypeImage = [UIImage imageNamed:((SearchType *)[searchTypeArray objectAtIndex:indexPath.row]).searchTypeImageName];
    }
    else if (indexPath.row == searchTypeArray.count)
    {
        searchTypeText = @"添加";
        searchTypeImage = [UIImage imageNamed:@"addSearchType"];
    }
    else
    {
        searchTypeText = @"";
    }
    cell.searchTypeLabel.text = searchTypeText;
    cell.searchTypeImageView.image = searchTypeImage;
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.collectionView.frame.size.width/3.0f, self.collectionView.frame.size.width/3.0f);
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
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    if (indexPath.row >= appDelegate.searchTypeArray.count)
    {
        //fnoztodo 添加搜索引擎
        return;
    }
    
    NSMutableArray *searchTypeArray = appDelegate.searchTypeArray;
    self.currentType = (SearchType *)[searchTypeArray objectAtIndex:indexPath.row];
    [self adjestSearchBgColor];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(indexPath.row) forKey:kSearchTypeCollectionCellID];
    if ([self.textField.text isEqualToString:@""]) //切换默认搜索引擎
    {
        [self.searchTypeBtn setImage:[UIImage imageNamed:self.currentType.searchTypeImageName] forState:UIControlStateNormal];
    }
    else //应用搜索引擎
    {
        [self.searchTypeBtn setImage:[UIImage imageNamed:self.currentType.searchTypeImageName] forState:UIControlStateNormal];
        [self search];
    }
    [self adjestSearchBgColor];
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

#pragma mark UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![self.textField.text isEqualToString:@""])
    {
        [self search];
    }
    else
    {
        [self.textField endEditing:YES];
    }
    return YES;
}

#pragma mark UIWebViewDelegate
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [self changeReloadBtnStatusIsReload:NO];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self changeReloadBtnStatusIsReload:YES];
}

#pragma mark Common
- (void)decorateWebViewContainer
{
    self.webViewContainer.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.webViewContainer.frame.size.width, self.webViewContainer.frame.size.height-48)];
    self.webView.delegate = self;
    self.webView.backgroundColor = self.webViewContainer.backgroundColor;
    [self.webViewContainer addSubview:self.webView];
}

- (void)decorateToolBar
{
    self.toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 48)];
    [self.view addSubview:self.toolBar];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0, 0, self.webViewContainer.frame.size.width, 1.0f);
    topBorder.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
    [self.toolBar.layer addSublayer:topBorder];
    
    UIButton *backPage = [[UIButton alloc] initWithFrame:CGRectMake(0, 1, self.view.frame.size.width/5.0, 47)];
    [backPage setImage:[UIImage imageNamed:@"backPage"] forState:UIControlStateNormal];
    backPage.imageEdgeInsets = UIEdgeInsetsMake(10, 10+0.5*(backPage.frame.size.width-47), 10, 10+0.5*(backPage.frame.size.width-47));
    [backPage addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:backPage];
    
    self.reloadPageBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/5.0, 1, self.view.frame.size.width/5.0, 47)];
    [self.reloadPageBtn setImage:[UIImage imageNamed:@"reloadPage"] forState:UIControlStateNormal];
    self.reloadPageBtn.imageEdgeInsets = UIEdgeInsetsMake(10, 10+0.5*(backPage.frame.size.width-47), 10, 10+0.5*(backPage.frame.size.width-47));
    [self.reloadPageBtn addTarget:self action:@selector(reloadPage) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:self.reloadPageBtn];
    
    UIButton *closeWebView = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/5.0*2, 1, self.view.frame.size.width/5.0, 47)];
    [closeWebView setImage:[UIImage imageNamed:@"home"] forState:UIControlStateNormal];
    closeWebView.imageEdgeInsets = UIEdgeInsetsMake(10, 10+0.5*(backPage.frame.size.width-47), 10, 10+0.5*(backPage.frame.size.width-47));
    [closeWebView addTarget:self action:@selector(closeWebView) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:closeWebView];
    
    UIButton *copyUrl = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/5.0*3, 1, self.view.frame.size.width/5.0, 47)];
    [copyUrl setImage:[UIImage imageNamed:@"copyUrl"] forState:UIControlStateNormal];
    copyUrl.imageEdgeInsets = UIEdgeInsetsMake(10, 10+0.5*(backPage.frame.size.width-47), 10, 10+0.5*(backPage.frame.size.width-47));
    [copyUrl addTarget:self action:@selector(copyUrl) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:copyUrl];
    
    UIButton *openInSafari = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/5.0*4, 1, self.view.frame.size.width/5.0, 47)];
    [openInSafari setImage:[UIImage imageNamed:@"openInSafari"] forState:UIControlStateNormal];
    openInSafari.imageEdgeInsets = UIEdgeInsetsMake(10, 10+0.5*(backPage.frame.size.width-47), 10, 10+0.5*(backPage.frame.size.width-47));
    [openInSafari addTarget:self action:@selector(openInSafari) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:openInSafari];
}

- (void)backPage
{
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
    else
    {
        [self closeWebView];
    }
}

- (void)reloadPage
{
    if ([self.webView isLoading]) {
        [self stopLoading];
    }
    else
    {
        [self reloading];
    }
}

- (void)closeWebView
{
    [self showWebViewContainer:NO];
}

- (void)copyUrl
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.webView.request.URL.absoluteString;
}

- (void)openInSafari
{
    [[UIApplication sharedApplication] openURL:self.webView.request.URL];
}

- (void)stopLoading
{
    [self.webView stopLoading];
    [self changeReloadBtnStatusIsReload:YES];
}

- (void)reloading
{
    [self.webView reload];
}

- (void)changeReloadBtnStatusIsReload:(BOOL)isReload
{
    if (isReload) {
        [self.reloadPageBtn setImage:[UIImage imageNamed:@"reloadPage"] forState:UIControlStateNormal];
    }
    else
    {
        [self.reloadPageBtn setImage:[UIImage imageNamed:@"stopLoad"] forState:UIControlStateNormal];
    }
}

- (void)searchBtnClicked
{
    if (![self.textField.text isEqualToString:@""])
    {
        [self search];
    }
    else
    {
        [self.textField endEditing:YES];
    }
}

- (void)search
{
    [self.textField endEditing:YES];
    [self showWebViewContainer:YES];
    NSString *searchKeyString = [self.textField.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url =[NSURL URLWithString:[NSString stringWithFormat:self.currentType.searchTypeModel, searchKeyString]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setValue: @"iPhone" forHTTPHeaderField: @"User-Agent"];
    
    [self.webView loadRequest:request];
}

- (void)showWebViewContainer:(BOOL)isShow
{
    AppDelegate *appDelegate = [AppDelegate sharedAppDelegate];
    NSIndexPath *index = [NSIndexPath indexPathForRow:[appDelegate.searchTypeArray indexOfObject:self.currentType] inSection:0];
    CGRect frameInWindows = [self.collectionView convertRect:[self.collectionView cellForItemAtIndexPath:index].frame toView:self.view];
    CGRect iconFrameInWindows = CGRectMake(frameInWindows.origin.x+frameInWindows.size.width*0.25, frameInWindows.origin.y+frameInWindows.size.height*0.2, frameInWindows.size.width*0.5, frameInWindows.size.width*0.5);
    if (isShow) {
        if (!self.webView) {
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-StatusBarHeight-48)];
            self.webView.delegate = self;
            self.webView.backgroundColor = self.webViewContainer.backgroundColor;
            [self.webViewContainer addSubview:self.webView];            
        }
        self.webViewContainer.hidden = NO;
        self.webViewContainer.frame = iconFrameInWindows;
        self.webViewContainer.alpha = 0.4;
        self.webViewContainer.layer.cornerRadius = iconFrameInWindows.size.width*0.5;
        NSLog(@"%lf", iconFrameInWindows.size.width*0.5);
        [self.view bringSubviewToFront:self.toolBar];
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.webViewContainer.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height-StatusBarHeight);
            self.webViewContainer.alpha = 0.7;
            self.toolBar.frame = CGRectMake(0, self.view.frame.size.height-48, self.view.frame.size.width, 48);
        } completion:^(BOOL finished) {
            self.webViewContainer.hidden = NO;
            self.webViewContainer.layer.cornerRadius = 0;
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.webViewContainer.alpha = 1;
            } completion:^(BOOL finished) {
                ;
            }];
        }];
    }
    else
    {
        [self.webView removeFromSuperview];
        self.webView = nil;
        self.webViewContainer.layer.cornerRadius = iconFrameInWindows.size.width/2.0;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.webViewContainer.frame = iconFrameInWindows;
            self.webViewContainer.alpha = 0.4;
            self.toolBar.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 48);
        } completion:^(BOOL finished) {
            self.webViewContainer.hidden = YES;
            self.webViewContainer.alpha = 0;
        }];
    }
}

- (void)adjestSearchBgColor
{
    UIColor *logoAverageColor = [Common mostColor:[UIImage imageNamed:self.currentType.searchTypeImageName]];
    
    const CGFloat *components = CGColorGetComponents(logoAverageColor.CGColor);
    UIColor *color = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:0.6];
    if ([Common isNearWhite:color])
    {
        color = [UIColor colorWithWhite:0.85 alpha:1];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.inputBgView.backgroundColor = color;
        if ([Common isDarkColor:color]) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        }
    }];
    
}

@end