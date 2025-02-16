//
//  LiveChatCell.m
//  CorpBoard
//
//  Created by Isaias Favela on 12/7/14.
//  Copyright (c) 2014 Justin Moore. All rights reserved.
//

#import "LiveChatCell.h"
#import "Corpsboard-Swift.h"

@implementation LiveChatCell

- (void)awakeFromNib {

    self.imgLastUser.layer.cornerRadius = self.imgLastUser.frame.size.width/2;
    self.imgLastUser.layer.masksToBounds = YES;
    self.imgLastUser.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imgLastUser.layer.borderWidth = 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    UIView * selectedBackgroundView = [[UIView alloc] init];
    [selectedBackgroundView setBackgroundColor:UISingleton.sharedInstance.gold];
    [self setSelectedBackgroundView:selectedBackgroundView];
}

@end
