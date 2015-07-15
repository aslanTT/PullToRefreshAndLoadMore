//
//  SCRefreshControl.h
//  SCPullRefresh
//
//  Created by Aslan on 12/7/15.
//  Copyright (c) 2015 Singro. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SCRefreshViewType) {
    SCBubbleTypeRefreshView,
    SCCircularTypeRefreshView
};

@interface SCRefreshControl : UIControl

@property (nonatomic, copy) void (^refreshBlock)();

- (void)beginRefresh;
- (void)endRefresh;

@property (nonatomic, copy) void (^loadMoreBlock)();

- (void)beginLoadMore;
- (void)endLoadMore;

- (instancetype) initWithScrollView:(UIScrollView *)scrollView
                        refreshType:(SCRefreshViewType)refreshType
                    appearanceColor:(UIColor *)appearanceColor;

@end
