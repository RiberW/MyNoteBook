//
//  DetailViewController.h
//  MyNoteBook
//
//  Created by Riber on 15/6/25.
//  Copyright (c) 2015年 314420972@qq.com. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MyNote;

@interface DetailViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

@property (nonatomic, retain) MyNote *myNote;
@property (nonatomic, assign) CGFloat navBarOrginY;

@property (nonatomic, copy) void(^clickDelBlock)();
@property (nonatomic, copy) void(^clickBackBlock)();

@end
