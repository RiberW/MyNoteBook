//
//  DetailViewController.m
//  MyNoteBook
//
//  Created by Riber on 15/6/25.
//  Copyright (c) 2015年 314420972@qq.com. All rights reserved.
//

#import "DetailViewController.h"
#import "MyNote.h"
#import "FMDBManager.h"

@interface DetailViewController () <UITextViewDelegate>

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
        
    if ([[[UIDevice currentDevice] systemVersion] integerValue] >= 7.0) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"删除" style: UIBarButtonItemStylePlain target:self action:@selector(pressItem:)];
    item.tag = 0;
    self.navigationItem.rightBarButtonItem = item;
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style: UIBarButtonItemStylePlain target:self action:@selector(backItem:)];
    self.navigationItem.leftBarButtonItem = leftItem;
    
    _dateLabel.text = _myNote.date;
    _textView.text = _myNote.content;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    // 状态栏高度
    float statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    // 导航条位置
    CGRect navFrame = self.navigationController.navigationBar.frame;
    navFrame.origin.y = statusHeight;
    self.navigationController.navigationBar.frame = navFrame;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_navBarOrginY >= 0)
    {
        // 状态栏高度
        float statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
        // 导航条位置
        CGRect navFrame = self.navigationController.navigationBar.frame;
        navFrame.origin.y = statusHeight;
        self.navigationController.navigationBar.frame = navFrame;
    }
    else
    {
        // 导航栏高度
        float navHeight = self.navigationController.navigationBar.frame.size.height;
        
        // 导航条位置
        CGRect navFrame = self.navigationController.navigationBar.frame;
        navFrame.origin.y = -navHeight;
        self.navigationController.navigationBar.frame = navFrame;
    }
}

- (void)pressItem:(UIBarButtonItem *)item {
    if (self.clickDelBlock) {
        self.clickDelBlock(item);
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)backItem:(UIBarButtonItem *)item {
    if (self.clickBackBlock) {
        self.clickBackBlock(self.myNote);
    }
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.myNote.content = textView.text;
}

@end
