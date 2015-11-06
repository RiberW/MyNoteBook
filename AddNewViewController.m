//
//  AddNewViewController.m
//  MyNoteBook
//
//  Created by Riber on 15/6/25.
//  Copyright (c) 2015年 314420972@qq.com. All rights reserved.
//

#import "AddNewViewController.h"

@interface AddNewViewController () <UITextViewDelegate>

@end

@implementation AddNewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    if(([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0)){
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"保存" style: UIBarButtonItemStylePlain target:self action:@selector(saveNewNote:)];
    self.navigationItem.rightBarButtonItem = item;

    self.dateLabel.text = [self getCurrentDateWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    self.textView.text = @"请在这里输入内容";
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style: UIBarButtonItemStylePlain target:self action:@selector(backItem:)];
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (void)backItem:(UIBarButtonItem *)item {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)saveNewNote:(UIBarButtonItem *)item {
    // 键盘退出
    [self.view endEditing:YES];
    if ([self.delegate respondsToSelector:@selector(sendNoteToMain:)]) {
        [self.delegate sendNoteToMain:self];
    } else {
        NSLog(@"失败");
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

// 格式化时间
- (NSString *)getCurrentDateWithFormat:(NSString *)dateFormat {
    NSString *currentDate = nil;
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = dateFormat;
    currentDate = [formatter stringFromDate:date];
    
    return currentDate;
}

// return键
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    if ([text isEqualToString:@"\n"]) {
//        [self saveNewNote:nil];
//        return NO; // return键不再换行
//    }
//    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:@"请在这里输入内容"]) {
        textView.text = nil;
    }
}

@end
