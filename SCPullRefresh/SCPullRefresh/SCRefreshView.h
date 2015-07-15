//
//  SCRefreshView.h
//  SCPullRefresh
//
//  Created by Aslan on 12/7/15.
//  Copyright (c) 2015 Singro. All rights reserved.
//

#import "SCRefreshView.h"

@interface SCRefreshView : UIView

@property (nonatomic, assign) BOOL isLoadMore;
@property (nonatomic, strong) UIColor *bubleColor;
@property (nonatomic, assign) CGFloat timeOffset;  // 0.0 ~ 1.0

- (instancetype)initWithFrame:(CGRect)frame bubleColor:(UIColor *)bubleColor;

- (void)beginRefreshing;
- (void)endRefreshing;

@end
