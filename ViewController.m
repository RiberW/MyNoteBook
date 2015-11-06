//
//  ViewController.m
//  MyNoteBook
//
//  Created by Riber on 15/6/24.
//  Copyright (c) 2015年 314420972@qq.com. All rights reserved.
//

#import "ViewController.h"
#import "MyCell.h"
#import "AddNewViewController.h"
#import "DetailViewController.h"
#import "FMDBManager.h"
#import "MyNote.h"

#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate,sendNoteToMain, UISearchBarDelegate, UIGestureRecognizerDelegate> {
    FMDBManager *manager;
    
    NSMutableArray *_searchArray;
    UISearchBar *_searchBar;
    UIView *_searchBarBgView;
    
    BOOL _isEdit; // 是否处于编辑状态
    BOOL _isSearch; // 是否处于搜索状态
    BOOL _isDelete;
    
    CGFloat keyBoardHeight; // 搜索时的键盘高度
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.title = @"Riber's 记事本";
    [self createUI];
    
    // 添加键盘监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    // 进入后台
    [[ NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground:) name:@"enterBackground" object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyBoardValue = userInfo[@"UIKeyboardFrameEndUserInfoKey"];
    CGRect keyboardRect = [keyBoardValue CGRectValue];
    keyBoardHeight = keyboardRect.size.height;
}


// 进入后台 处理
- (void)enterBackground:(NSNotification *)notification {
    [self searchBarCancelButtonClicked:_searchBar];
}

- (void)createUI {
    // 初始化数据源
    self.dataSources = [[NSMutableArray alloc] init];
    _searchArray = [[NSMutableArray alloc] init];
    manager = [FMDBManager sharedDBManager];
    [manager createTable];
    NSArray *array = [manager selectNotes];
    [_dataSources addObjectsFromArray:array];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 64+40, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:imageView];

    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewNote:)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(pressLeftBar:)];
    
    // 状态栏高度
    float statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    // 导航栏高度
    float navHeight = self.navigationController.navigationBar.frame.size.height;
    
    // 初始化搜索框的背景
    _searchBarBgView = [[UIView alloc] initWithFrame:CGRectMake(0, navHeight, self.view.frame.size.width, statusHeight+40)];
    _searchBarBgView.backgroundColor = [UIColor colorWithRed:198/255.0 green:198/255.0 blue:203/255.0 alpha:1];
    [self.view addSubview:_searchBarBgView];
    
    // 初始化搜索框
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, statusHeight, self.view.frame.size.width, 40)];
    _searchBar.placeholder = @"请输入要搜索的内容";
    _searchBar.delegate = self;
    [_searchBarBgView addSubview:_searchBar];
    
    // 去掉 searchBar 的边线
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, statusHeight+2)];
    view.backgroundColor = [UIColor colorWithRed:198/255.0 green:198/255.0 blue:203/255.0 alpha:1];
    [_searchBarBgView addSubview:view];

    NSLog(@"%@", [_searchBar.subviews[0] subviews]);
    
    // collectionView布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 10;
    layout.itemSize = CGSizeMake(100, 100);
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, statusHeight+navHeight+_searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height-statusHeight-navHeight-40) collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor darkGrayColor];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_collectionView];
    
    // 注册cell
    [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([MyCell class]) bundle:nil] forCellWithReuseIdentifier:@"MYCELL"];
    
    // 给 view 添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.delegate = self;
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.collectionView addGestureRecognizer:tap];
}

#pragma mark - 导航按钮事件
- (void)pressLeftBar:(UIBarButtonItem *)item {
    if (_isEdit)
    {
        _isEdit = NO;
        item.title = @"Edit";
        UIView *view = [_searchBarBgView viewWithTag:998];
        [view removeFromSuperview];

        self.navigationItem.rightBarButtonItem.enabled = YES;
        
        // 这样写 有的cell 不会停止抖动
//        NSArray *cellArray = [self.collectionView visibleCells];
//        for (MyCell *cell in cellArray) {
//            [cell endWobble];
//        }
        
        [_collectionView reloadData];
    }
    else
    {
        _isEdit = YES;
        item.title = @"Done";
        self.navigationItem.rightBarButtonItem.enabled = NO;

        // 使搜索框不可输入
        UIView *view = [[UIView alloc] initWithFrame:_searchBar.frame];
        view.backgroundColor = [UIColor lightGrayColor];
        view.tag = 998;
        view.alpha = 0.2;
        [_searchBarBgView addSubview:view];
        
        NSArray *cellArray = [self.collectionView visibleCells];
        for (MyCell *cell in cellArray) {
            [cell startWobble];
        }
    }
}

// 跳转添加页面
- (void)addNewNote:(UIBarButtonItem *)item {
    AddNewViewController *addNewVC = [[AddNewViewController alloc] init];
    addNewVC.delegate = self;
    addNewVC.title = @"添加新事件";
    [self.navigationController pushViewController:addNewVC animated:YES];
}

#pragma mark - 手势代理方法
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{

    if (_searchBar.text.length == 0)
    {
        [self.view endEditing:YES];
        _searchBar.showsCancelButton = NO;
        _isSearch = YES;
        
        [UIView animateWithDuration:0.3 animations:^{
            // 状态栏高度
            float statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
            // 导航栏高度
            float navHeight = self.navigationController.navigationBar.frame.size.height;
            
            // 导航条位置
            CGRect navFrame = self.navigationController.navigationBar.frame;
            navFrame.origin.y = statusHeight;
            self.navigationController.navigationBar.frame = navFrame;
            
            // 搜索框位置
            CGRect searchBarFrame = _searchBarBgView.frame;
            searchBarFrame.origin.y = navHeight;
            _searchBarBgView.frame = searchBarFrame;
            
            // collectionView 位置
            CGRect collectionViewFrame = _collectionView.frame;
            collectionViewFrame.origin.y = navHeight + _searchBarBgView.frame.size.height;
            collectionViewFrame.size.height = self.view.frame.size.height - collectionViewFrame.origin.y;
            _collectionView.frame = collectionViewFrame;
        } completion:^(BOOL finished) {
            
            _isSearch = NO;
        }];

        return NO;
    }
    
    return NO;
}

#pragma mark - collectionView代理方法
// collectionView dataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_searchBar.text.length == 0 || _searchBar.text == nil) {
        return _dataSources.count;
    } else {
        return _searchArray.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MYCELL" forIndexPath:indexPath];
    
    MyNote *tmpNote = nil;
    if (_searchBar.text.length == 0 || _searchBar.text == nil) {
        tmpNote = _dataSources[indexPath.row];
    } else {
        tmpNote = _searchArray[indexPath.row];
    }
    cell.label.text = tmpNote.content;
    
    __block typeof(cell)myCell = cell;
    [cell setLongPressBlock:^(int index) {
        if (index == 0) { // 单选删除
            _isEdit = NO;
            myCell.isEdit = _isEdit;
            [manager deleteNote:tmpNote];
            // 不能根据索引删除,造成越界
            [_dataSources removeObject:tmpNote];
            [_collectionView reloadData];
        }
        
        // 实现抖动 多选删除
        if (index == 1) {
            // 在置为yes之前调用 并且在这里只调用一次 不会多次叠加 view
            [self pressLeftBar:nil];
            _isEdit = YES;
            myCell.isEdit = _isEdit;
            [collectionView reloadData];
        }
    }];
    
    if (_isEdit) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.leftBarButtonItem.title = @"Done";

        // 使 searchBar 搜索不可用 在这里写 会有问题 已弃用
//        UIView *view = [[UIView alloc] initWithFrame:_searchBar.frame];
//        view.backgroundColor = [UIColor lightGrayColor];
//        view.tag = 998;
//        view.alpha = 0.2;
//        [self.view addSubview:view];
        
        [cell startWobble];
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        
//        UIView *view = [self.view viewWithTag:998];
//        [view removeFromSuperview];
        
        [cell endWobble];
    }
    
    return cell;
}

// collectionView delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_isEdit)
    {
        [manager deleteNote:_dataSources[indexPath.row]];
        [_dataSources removeObjectAtIndex:indexPath.row];
        if (_searchArray.count != 0) {
            [_searchArray removeObjectAtIndex:indexPath.row];
        }
        [_collectionView reloadData];
    }
    else if (_isSearch)
    {
        // 处于搜索时 点击collectionView 退出搜索 如果是点在详情页面上 使其不进入详情页面
        _isSearch = NO;
    }
    else
    {
        DetailViewController *detailVC = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailVC.title = @"查看详情";
        detailVC.myNote = _searchBar.text.length == 0?_dataSources[indexPath.row]:_searchArray[indexPath.row];
        detailVC.navBarOrginY = self.navigationController.navigationBar.frame.origin.y;
        detailVC.clickDelBlock = ^(UIBarButtonItem *item) {
            if (_searchBar.text.length == 0)
            {
                [manager deleteNote:_dataSources[indexPath.row]];
                [_dataSources removeObjectAtIndex:indexPath.row];
                [_collectionView deleteItemsAtIndexPaths:@[indexPath]];
            }
            else
            {
                [manager deleteNote:_searchArray[indexPath.row]];
                [_dataSources removeObject:_searchArray[indexPath.row]];
                [_searchArray removeObjectAtIndex:indexPath.row];
                [_collectionView deleteItemsAtIndexPaths:@[indexPath]];
            }
        };
        [self.navigationController pushViewController:detailVC animated:YES];
        detailVC.clickBackBlock = ^(MyNote *note) {
            [manager updateMyNote:note];
            [_collectionView reloadData];
        };
    }
}

#pragma mark - 添加页面代理方法
- (void)sendNoteToMain:(AddNewViewController *)addVC {
    MyNote *tmpNote = [[MyNote alloc] init];
    tmpNote.date = addVC.dateLabel.text;
    tmpNote.content = addVC.textView.text;
    
    // 判断最后一个元素不为空格
    // [[addVC.textView.text substringFromIndex:tmpNote.content.length-1] isEqualToString:@" "]
    if (addVC.textView.text.length == 0) {
        return;
    }
    
    [manager addNewNote:tmpNote];
    [_dataSources addObject:tmpNote];
    
    [_collectionView reloadData];
}

#pragma mark - searchBar deleagte
// searchBar deleagte
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
    
    [_collectionView setContentOffset:CGPointZero animated:NO];
    [UIView animateWithDuration:0.3 animations:^{
        // 导航栏高度
        float navHeight = self.navigationController.navigationBar.frame.size.height;
        
        if (navHeight >= 0) {
            // 导航条位置
            CGRect navFrame = self.navigationController.navigationBar.frame;
            navFrame.origin.y = -navHeight;
            self.navigationController.navigationBar.frame = navFrame;
            
            // 搜索框位置
            CGRect searchBarBgFrame = _searchBarBgView.frame;
            searchBarBgFrame.origin.y = 0;
            _searchBarBgView.frame = searchBarBgFrame;
            
            // collectionView 位置
            CGRect collectionViewFrame = _collectionView.frame;
            collectionViewFrame.origin.y =  _searchBarBgView.frame.size.height;
            collectionViewFrame.size.height = self.view.frame.size.height - collectionViewFrame.origin.y - keyBoardHeight;
            _collectionView.frame = collectionViewFrame;
        }
        
    } completion:^(BOOL finished) {
    }];
    
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    // collectionView 位置
    if (searchText.length == 0)
    {
        CGRect collectionViewFrame = _collectionView.frame;
        collectionViewFrame.origin.y =  _searchBarBgView.frame.size.height;
        collectionViewFrame.size.height = self.view.frame.size.height - collectionViewFrame.origin.y - keyBoardHeight;
        _collectionView.frame = collectionViewFrame;
    }
    else
    {
        CGRect collectionViewFrame = _collectionView.frame;
        collectionViewFrame.origin.y =  _searchBarBgView.frame.size.height;
        collectionViewFrame.size.height = self.view.frame.size.height - collectionViewFrame.origin.y - keyBoardHeight - 40;
        _collectionView.frame = collectionViewFrame;
    }
    
    [_searchArray removeAllObjects];
    for (MyNote *note in _dataSources) {
        
        // 搜索内容和文本内容都转化为拼音
        NSRange range = [[self supportPinYinSearch:[note.content lowercaseString]] rangeOfString:[self supportPinYinSearch:[searchBar.text lowercaseString]]];
        if (range.location != NSNotFound) {
            [_searchArray addObject:note];
        }
    }
    
    [_collectionView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = NO;
    _isSearch = NO;
    searchBar.text = nil;
    [searchBar resignFirstResponder];
    
    [UIView animateWithDuration:0.3 animations:^{
        // 状态栏高度
        float statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        // 导航栏高度
        float navHeight = self.navigationController.navigationBar.frame.size.height;

        // 导航条位置
        CGRect navFrame = self.navigationController.navigationBar.frame;
        navFrame.origin.y = statusHeight;
        self.navigationController.navigationBar.frame = navFrame;
        
        // 搜索框位置
        CGRect searchBarFrame = _searchBarBgView.frame;
        searchBarFrame.origin.y = navHeight;
        _searchBarBgView.frame = searchBarFrame;
        
        // collectionView 位置
        CGRect collectionViewFrame = _collectionView.frame;
        collectionViewFrame.origin.y = navHeight + _searchBarBgView.frame.size.height;
        collectionViewFrame.size.height = self.view.frame.size.height - collectionViewFrame.origin.y;
        _collectionView.frame = collectionViewFrame;
    } completion:^(BOOL finished) {
    }];
    
    [_collectionView reloadData];
}

// 支持拼音搜索
- (NSString *)supportPinYinSearch:(NSString*)sourceString {
    NSMutableString *source = [sourceString mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)source, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)source, NULL, kCFStringTransformStripDiacritics, NO);
    
    return [source stringByReplacingOccurrencesOfString:@" " withString:@""];;
}

@end
