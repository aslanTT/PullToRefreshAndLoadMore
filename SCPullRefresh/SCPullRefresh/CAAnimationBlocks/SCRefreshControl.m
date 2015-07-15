//
//  SCRefreshControl.m
//  SCPullRefresh
//
//  Created by Aslan on 12/7/15.
//  Copyright (c) 2015 Singro. All rights reserved.
//

#import "SCRefreshControl.h"
#import "SCRefreshView.h"
#import "SCBubbleRefreshView.h"
#import "SCCircularRefreshView.h"

static void *SCRefreshControlContext = &SCRefreshControlContext;

#define kSCRrefreshTotalViewHeight    400
#define kSCRefreshHeight              44
#define kSCScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kSCScreenHeight ([UIScreen mainScreen].bounds.size.height)

@interface SCRefreshControl ()

@property (nonatomic, strong) SCRefreshView *refreshView;
@property (nonatomic, strong) SCRefreshView *loadMoreView;

@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) CGFloat scrollViewInsetTop;
@property (nonatomic, assign) BOOL lastDragging;
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) BOOL hadLoadMore;

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation SCRefreshControl

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (!newSuperview) {
        [self.scrollView removeObserver:self forKeyPath:@"contentOffset" context:SCRefreshControlContext];
        [self.scrollView removeObserver:self forKeyPath:@"contentSize" context:SCRefreshControlContext];
        self.scrollView = nil;
    }
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
                       refreshType:(SCRefreshViewType)refreshType
                   appearanceColor:(UIColor *)appearanceColor
{
    self = [super initWithFrame:CGRectMake(0,
                                           -(kSCRrefreshTotalViewHeight + scrollView.contentInset.top),
                                           scrollView.frame.size.width,
                                           kSCRrefreshTotalViewHeight)];
    if (self) {
        self.scrollView = scrollView;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        if (self.scrollView) {
            [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:SCRefreshControlContext];
            [self.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:SCRefreshControlContext];
        }
        
        _isRefreshing = NO;
        _hadLoadMore = NO;
        _isLoadingMore = NO;
        
        switch (refreshType) {
            case SCBubbleTypeRefreshView:
            {
                self.refreshView = [[SCBubbleRefreshView alloc] initWithFrame:(CGRect){40, 0, self.scrollView.width - 80, kSCRefreshHeight}
                                                                   bubleColor:appearanceColor];
                self.loadMoreView = [[SCBubbleRefreshView alloc] initWithFrame:(CGRect){40, self.scrollView.contentSize.height, self.scrollView.width - 80, kSCRefreshHeight}
                                                                    bubleColor:appearanceColor];
            }
                break;
            case SCCircularTypeRefreshView:
            default:
            {
                self.refreshView = [[SCCircularRefreshView alloc] initWithFrame:(CGRect){40, 0, self.scrollView.width - 80, kSCRefreshHeight}
                                                                     bubleColor:appearanceColor];
                self.loadMoreView = [[SCCircularRefreshView alloc] initWithFrame:(CGRect){40, self.scrollView.contentSize.height, self.scrollView.width - 80, kSCRefreshHeight}
                                                                      bubleColor:appearanceColor];
            }
                break;
        }
        
        self.refreshView.timeOffset = 0.0;
        self.loadMoreView.timeOffset = 0.0;
        
        self.scrollViewInsetTop = 64;
        [self.scrollView addSubview:self.refreshView];
        [self.scrollView addSubview:self.loadMoreView];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == SCRefreshControlContext) {
        if ([keyPath isEqualToString:@"contentSize"]) {
            if (self.loadMoreBlock) {
                [self.loadMoreView setFrame:CGRectMake(0, self.scrollView.contentSize.height, self.scrollView.width, kSCRefreshHeight)];
            }
        } else if ([keyPath isEqualToString:@"contentOffset"]) {
            if (!CGPointEqualToPoint(_contentOffset, _scrollView.contentOffset)) {
                [self _scrollViewDidScroll:_scrollView];
            }
            _contentOffset = _scrollView.contentOffset;
            if (_lastDragging && !_scrollView.dragging) {
                _lastDragging = NO;
                [self _scrollViewDidEndDragging:_scrollView willDecelerate:YES];
            }
            _lastDragging = _scrollView.dragging;
        }
    }
}

- (void)_scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Refresh
    CGFloat offsetY = - scrollView.contentOffsetY - self.scrollViewInsetTop - 25;
    
    self.refreshView.timeOffset = MAX(offsetY / 60.0, 0);
    
    // LoadMore
    if ((self.loadMoreBlock && scrollView.contentSizeHeight > 300) || !self.hadLoadMore) {
        self.loadMoreView.hidden = NO;
    } else {
        self.loadMoreView.hidden = YES;
    }
    
    if (scrollView.contentSizeHeight + scrollView.contentInsetTop < [UIScreen mainScreen].bounds.size.height) {
        return;
    }
    
    CGFloat loadMoreOffset = - (scrollView.contentSizeHeight - scrollView.superview.height - scrollView.contentOffsetY + scrollView.contentInsetBottom);
    
    if (loadMoreOffset > 0) {
        self.loadMoreView.timeOffset = MAX(loadMoreOffset / 60.0, 0);
    } else {
        self.loadMoreView.timeOffset = 0;
    }
}

- (void)_scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // Refresh
    CGFloat refreshOffset = -scrollView.contentOffsetY - scrollView.contentInsetTop;
    if (refreshOffset > 60 && self.refreshBlock && !self.isRefreshing) {
        [self beginRefresh];
    }
    
    // loadMore
    CGFloat loadMoreOffset = scrollView.contentSizeHeight - scrollView.superview.height - scrollView.contentOffsetY + scrollView.contentInsetBottom;
    if (loadMoreOffset < -60 && self.loadMoreBlock && !self.isLoadingMore && scrollView.contentSizeHeight > [UIScreen mainScreen].bounds.size.height) {
        [self beginLoadMore];
    }
}

#pragma mark - Public Methods

- (void)setRefreshBlock:(void (^)())refreshBlock
{
    _refreshBlock = refreshBlock;
    self.refreshView.frame = CGRectMake(40, -kSCRefreshHeight, self.scrollView.width - 80, kSCRefreshHeight);
}

- (void)beginRefresh
{
    if (self.isRefreshing) {
        return;
    }
    self.isRefreshing = YES;
    [self.refreshView beginRefreshing];
    
    if (self.refreshBlock) {
        self.refreshBlock();
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.scrollView.contentInsetTop = kSCRefreshHeight + self.scrollViewInsetTop;
        } completion:^(BOOL finished){
        }];
    });
}

- (void)endRefresh
{
    [self.refreshView endRefreshing];
    self.isRefreshing = NO;

    [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.contentInsetTop = self.scrollViewInsetTop;
    }];
}

- (void)beginLoadMore {
    
    [self.loadMoreView beginRefreshing];
    
    self.isLoadingMore = YES;
    self.hadLoadMore = YES;
    
    if (self.loadMoreBlock) {
        self.loadMoreBlock();
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.scrollView.contentInsetBottom = kSCRefreshHeight;
        } completion:^(BOOL finished){
        }];
    });
}

- (void)endLoadMore
{
    [self.loadMoreView endRefreshing];
    self.isLoadingMore = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.contentInsetBottom = 0;
    }];
    
}

- (void)setLoadMoreBlock:(void (^)())loadMoreBlock
{
    _loadMoreBlock = loadMoreBlock;
}

@end
