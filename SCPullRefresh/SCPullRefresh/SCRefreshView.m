//
//  SCRefreshView.m
//  SCPullRefresh
//
//  Created by Aslan on 12/7/15.
//  Copyright (c) 2015 Singro. All rights reserved.
//

#import "SCRefreshView.h"

@implementation SCRefreshView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame bubleColor:[UIColor orangeColor]];
}

- (instancetype)initWithFrame:(CGRect)frame bubleColor:(UIColor *)bubleColor
{
    if (self = [super initWithFrame:frame]) {
        self.bubleColor = bubleColor;
    }
    return self;
}

- (void)beginRefreshing
{
    // subview
}

- (void)endRefreshing
{
    // subview
}

@end
