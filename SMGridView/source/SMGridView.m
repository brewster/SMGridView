//
//  SMGridView.m
//  SMGridView
//
//  Created by Miguel Cohnen and Sarah Lensing on 28/10/11.
//

#import "SMGridView.h"
#import <QuartzCore/QuartzCore.h>

#define CGPointDistance(p1,p2) sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))

//#define kSMGridViewDebug 1

static CGFloat const kSMTVdefaultPadding = 5;
// Defines extra px to preload
static CGFloat const kSMTVdefaultDeltaLoad = 150;
static CGFloat const kSMTVdefaultPagesToPreload = 1;
static float const kSMTVanimDuration = 0.2;
static float const kSMTdefaultDragMinDistance = 30;
static float const kSMdefaultBucketSize = 500;

enum {
    SMGridViewSortAnimSpeedNone,
    SMGridViewSortAnimSpeedSlow,
    SMGridViewSortAnimSpeedMid,
    SMGridViewSortAnimSpeedFast,
};
typedef NSUInteger SMGridViewSortAnimSpeed;


@interface SMGridViewItem : NSObject <NSCopying> {    
}

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) UIView *view;
@property (nonatomic, assign) BOOL toAdd;
@property (nonatomic, assign) BOOL header;
@property (nonatomic, readonly) BOOL visible;
@property (nonatomic, readonly) CGPoint centerPoint;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) NSMutableArray *buckets;

- (id)initWithRect:(CGRect)rect;

@end


@implementation SMGridViewItem

@synthesize rect;
@synthesize view;
@synthesize toAdd;
@synthesize header;
@synthesize indexPath = _indexPath;
@synthesize buckets = _buckets;

- (id)initWithRect:(CGRect)frame {
    self = [self init];
    if (self) {
        self.rect = frame;
    }
    return self;
}

- (void)dealloc {
    [_indexPath release];
    [_buckets release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Index:%@ Frame:%@, toAdd:%d, view:%@ header:%d", self.indexPath, NSStringFromCGRect(rect), toAdd, view!=nil?@"Y":@"N", header];
}

- (CGPoint)centerPoint {
    return CGPointMake(CGRectGetMidX(self.rect), CGRectGetMidY(self.rect));
}

- (BOOL)visible {
    return view != nil;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[SMGridViewItem class]]) {
        SMGridViewItem *other = (SMGridViewItem *)object;
        return [self.indexPath isEqual:other.indexPath] && self.header == other.header;
    }
    return NO;
}

- (NSUInteger)hash {
    return self.indexPath.hash + (self.header?1:0);
}

- (id)copyWithZone:(NSZone *)zone {
    SMGridViewItem *item = [SMGridViewItem allocWithZone:zone];
    item.rect = self.rect;
    item.header = self.header;
    item.view = self.view;
    item.toAdd = self.toAdd;
    item.indexPath = self.indexPath;
    item.buckets = self.buckets;
    return item;
}

@end


////////////////////////////////////////////////////////////////////////////////////////////
@interface SMGridView() {
    CGPoint _lastOffset;
    SMGridViewSortAnimSpeed _draggingSpeed;
}

- (BOOL)loaderEnabled;
- (void)handleLoaderDisplay:(CGRect)rect;
- (void)updateEmptyView;
- (CGFloat)findMaxValue;

@property (nonatomic, retain) NSTimer *dragAnimTimer;
@property (nonatomic, retain) NSTimer *dragStartAnimTimer;
@property (nonatomic, retain) NSTimer *dragPageAnimTimer;
@property (nonatomic, retain) UIView *draggingView;
@property (nonatomic, retain) NSMutableArray *posArray;
@property (nonatomic, retain) NSMutableArray *posArrays;
@property (nonatomic, retain) NSIndexPath *removingIndexPath;
@property (nonatomic, retain) NSIndexPath *addingIndexPath;

@end


@implementation SMGridView

@synthesize dataSource = _dataSource;
@synthesize gridDelegate = _gridDelegate;
@synthesize posArray = _posArray;
@synthesize posArrays = _posArrays;
@synthesize removingIndexPath = _removingIndexPath;
@synthesize addingIndexPath = _addingIndexPath;
@synthesize numberOfRows;
@synthesize padding  = _padding;

@synthesize deltaLoad;
@synthesize deltaLoaderView;
@synthesize pagesToPreload;
@synthesize vertical = _vertical;
@synthesize pagingInverseOrder = _pagingInverseOrder;
@synthesize sortWaitBeforeAnimate = _sortWaitBeforeAnimate;
@synthesize currentPage = _currentPage;
@synthesize loaderView = _loaderView;
@synthesize emptyView = _emptyView;
@synthesize enableSort = _enableSort;
@synthesize dragMinDistance = _dragMinDistance;
@synthesize dragAnimTimer = _dragAnimTimer;
@synthesize dragStartAnimTimer = _dragStartAnimTimer;
@synthesize dragPageAnimTimer = _dragPageAnimTimer;
@synthesize draggingPoint = _draggingPoint;
@synthesize draggingView = _draggingView;
@synthesize stickyHeaders = _stickyHeaders;
@synthesize currentSection = _currentSection;

#pragma mark - Life flow

- (void)setup {
    self.delegate = self;
    _reusableViews = [[NSMutableArray alloc] init];
    self.numberOfRows = 1;
    self.clipsToBounds = YES;
    self.padding = kSMTVdefaultPadding;
    self.deltaLoad = kSMTVdefaultDeltaLoad;
    self.deltaLoaderView = kSMTVdefaultDeltaLoad;
    self.pagesToPreload = kSMTVdefaultPagesToPreload;
    _enableSort = NO;
    _draggingItemsIndex = -1;
    _dragMinDistance = kSMTdefaultDragMinDistance;
    _currentOffsetPage = -1;
    _draggingOrigItemsIndex = -1;
    _draggingSection = -1;
    _sortWaitBeforeAnimate = .05;
    _bucketItems = [[NSMutableArray alloc] init];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [_dragAnimTimer invalidate];
    [_dragAnimTimer release];
    [_dragStartAnimTimer invalidate];
    [_dragStartAnimTimer release];
    [_dragPageAnimTimer invalidate];
    [_dragPageAnimTimer release];
    [_items release];
    [_reusableViews release];
    [_loaderView release];
    [_emptyView release];
    [_draggingView release];
    [_removingIndexPath release];
    [_addingIndexPath release];
    _draggingView = nil;
    
    [super dealloc];
}


# pragma mark - Reuse views

- (UIView *)dequeReusableView {
    return [self dequeReusableViewOfClass:0];
}

- (UIView *)dequeReusableViewOfClass:(Class)class {
    if (_reusableViews.count > 0) {
        for (UIView *view in _reusableViews) {
            if ([view isMemberOfClass:class] || !class) {
                [[view retain] autorelease];
                [_reusableViews removeObject:view];
                view.alpha = 1.0;
                return view;
            }
        }
    }
    return nil;
}

- (void)queView:(SMGridViewItem *)item {
    UIView *view = item.view;
    if (view == _draggingView) {
        return;
    }
    if (!item.header) {
        if ([_dataSource respondsToSelector:@selector(smGridView:willQueueView:)]) {
            [_dataSource performSelector:@selector(smGridView:willQueueView:) withObject:self withObject:view];
        }
        [_reusableViews addObject:view];
    }
    item.view = nil;
    [view removeFromSuperview];
}

- (void)clearReusableViews {
    [_reusableViews removeAllObjects];
}

#pragma mark - Show views

- (void)adjustNewViewPosition:(UIView *)view {
    // Send back because we want scroll indicators on top
    [self sendSubviewToBack:view];
    if (_loaderView.superview) {
        [self sendSubviewToBack:_loaderView];
    }
}

- (NSIndexPath *)calculateSortDataSourceIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != _draggingSection || _draggingOrigItemsIndex < 0 ) {
        return indexPath;
    }
    int index = indexPath.row;
    NSArray *items = [self itemsInSection:_draggingSection];

    if (index >= _draggingOrigItemsIndex && index < _draggingItemsIndex && index < (items.count-1)) {
        return [NSIndexPath indexPathForRow:index+1 inSection:indexPath.section];
    }
    if (index <= _draggingOrigItemsIndex && _draggingItemsIndex < _draggingOrigItemsIndex && index > 0 && index >=_draggingItemsIndex) {
        return [NSIndexPath indexPathForRow:index-1 inSection:indexPath.section];
    }
    return indexPath;
}

- (NSIndexPath *)adjustAddIndexPath:(NSIndexPath *)indexPath {
    if (self.addingIndexPath && self.addingIndexPath.section == indexPath.section && indexPath.row >= self.addingIndexPath.row) {
        return [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
    } else {
        return indexPath;
    }
}

- (UIView *)dataSourceViewForIndexPath:(NSIndexPath *)indexPath {
    return [_dataSource smGridView:self viewForIndexPath:[self adjustAddIndexPath:indexPath]];
}

- (UIView *)dataSourceViewForItem:(SMGridViewItem *)item {
    if (item.header) {
        if ([_dataSource respondsToSelector:@selector(smGridView:viewForHeaderInSection:)]) {
            return [_dataSource smGridView:self viewForHeaderInSection:item.indexPath.section];
        } else {
            return nil;
        }
    } else {
        return [self dataSourceViewForIndexPath:[self calculateSortDataSourceIndexPath:item.indexPath]];
    }
}

- (void)addItemToVisibles:(SMGridViewItem *)item {
    if (!_visibleItems) {
        _visibleItems = [[NSMutableArray alloc] init];
    }
    [_visibleItems addObject:item];
}

- (void)removeItemFromVisibles:(SMGridViewItem *)item {
    [_visibleItems removeObject:item];
}

- (void)addViewForItem:(SMGridViewItem *)item {
    UIView *view = [self dataSourceViewForItem:item];
    CGRect frame = view.frame;
    CGRect rect = item.rect;
    frame.origin.x = rect.origin.x;
    frame.origin.y = rect.origin.y;
    view.frame = frame;
    [self addSubview:view];
    if (!item.header) {
        [self adjustNewViewPosition:view];
    }
    
    item.view = view;
    item.view.hidden = item.toAdd;
    
    if (!item.header) {
        [self addSorting:view];
    }
    [self addItemToVisibles:item];
}

- (BOOL)headerStickyNeedsAdjustment:(SMGridViewItem *)item {
    if (!item.view) {
        return NO;
    }
    if (self.vertical) {
        if (self.contentOffset.y > CGRectGetMinY(item.rect)) {
            return YES;
        }
    } else {
        if (self.contentOffset.x > CGRectGetMinX(item.rect)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isCurrentHeaderItemSticky:(SMGridViewItem *)item {
    BOOL ret = self.stickyHeaders && item.header && !CGRectIsEmpty(item.rect) && item.indexPath.section == _currentSection && !CGSizeEqualToSize(CGSizeZero, item.rect.size);
    if (ret) {
        NSLog(@"");
    }
    return ret;
}

- (CGRect)rectForIndexPath:(NSIndexPath *)indexPath {
    SMGridViewItem *item = [self itemAtIndexPath:indexPath];
    return item.rect;
}

- (void)updateRectForItem:(SMGridViewItem *)item {
    if (item.header) {
        NSLog(@"");
    }
    if ([self isCurrentHeaderItemSticky:item]) {
        SMGridViewItem *headerNextItem = [self headerItemInSection:_currentSection+1];
        if ([self headerStickyNeedsAdjustment:item]) {            
            CGRect frame = item.rect;
            if (self.vertical) {
                frame.origin.y = self.contentOffset.y;
                if (CGRectIntersectsRect(headerNextItem.rect, frame)) {
                    frame.origin.y -= CGRectGetMaxY(frame) - CGRectGetMinY(headerNextItem.rect);
                }
            } else {
                frame.origin.x = self.contentOffset.x;
                if (CGRectIntersectsRect(headerNextItem.rect, frame)) {
                    frame.origin.x -= CGRectGetMaxX(frame) - CGRectGetMinX(headerNextItem.rect);
                }
            }
            item.view.frame = frame;
            return;
        }
    }
    if (item.view && item.view != _draggingView) {
        CGRect rect = item.view.frame;
        rect.origin = item.rect.origin;
        item.view.frame = rect;
    }
}

- (CGFloat)calculateDelta {
    if (self.pagingEnabled) {
        if (self.vertical) {
            return self.frame.size.height * self.pagesToPreload;
        }else {
            return self.frame.size.width * self.pagesToPreload;
        }
    }else {
        return self.deltaLoad;
    }
}

- (CGRect)calculateLoadRect:(NSInteger)pos delta:(float)delta {
    if (self.vertical) {
        return CGRectMake(0, pos - delta, self.frame.size.width, self.frame.size.height + 2*delta);
    }else {
        return CGRectMake(pos - delta, 0, self.frame.size.width + 2*delta, self.frame.size.height);
    }
}

- (BOOL)isDraggingIndexPath:(NSIndexPath *)indexPath {
    return [indexPath isEqual:[NSIndexPath indexPathForRow:_draggingItemsIndex inSection:_draggingSection]];
}

- (void)updateCurrentSection {
    int headerSection = 0;
    for (int section = [self numberOfSections]-1; section >= 0; section--) {
        SMGridViewItem *item = [self headerItemInSection:section];
        if (self.vertical) {
            if (self.contentOffset.y > CGRectGetMinY(item.rect)) {
                headerSection = section;
                break;
            }
        } else {
            if (self.contentOffset.x > CGRectGetMinX(item.rect)) {
                headerSection = section;
                break;
            }
        }
    }
    _currentSection = headerSection;
}

- (void)sameSizeLoadViewsForPos:(float)pos addedIndexes:(NSMutableArray *)addedIndexes {
    pos = MAX(pos, 0);
    [self updateCurrentSection];
    CGRect loadRect = [self calculateLoadRect:pos delta:[self calculateDelta]];
    int section = 0;
    for (section = 0; section < [self numberOfSections]; section++) {
        float sectionMax = [self findMaxValueInSection:section];
        if (pos <= sectionMax) {
            break;
        }
    }
    // Get first item
    SMGridViewItem *firstItem = [[self itemsInSection:section] objectAtIndex:0];
    float posInSection = MAX(0, pos - [self findMinValueInSection:section]);
    float varDim = self.vertical?firstItem.rect.size.height:firstItem.rect.size.width;
    int row = posInSection/(varDim+self.padding);
    int firstItemRow = row * [self numberOfRowsInSection:section];
    
    NSMutableDictionary *addedItems = [NSMutableDictionary dictionary];
    __block int count = 0;
    [self loopItemsStarting:[NSIndexPath indexPathForRow:firstItemRow inSection:section] block:^(SMGridViewItem *item, BOOL *stop) {
#ifdef kSMGridViewDebug
        NSDate *date = [NSDate date];
#endif
        if (CGRectIntersectsRect(loadRect, item.rect) || [self isCurrentHeaderItemSticky:item]) {
            if (!item.visible) {
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [self addViewForItem:item];
                [CATransaction commit];
                
                if (addedIndexes && !item.header) {
                    [addedIndexes addObject:item.indexPath];
                }
            } 
            [addedItems setObject:[NSNumber numberWithBool:YES] forKey:item];
        } else {
            if (!item.header) {
                *stop = YES;
            }
        }
        count++;
        [self updateRectForItem:item];
#ifdef kSMGridViewDebug
        NSLog(@"loopItem:%f",[date timeIntervalSinceNow]);
#endif
    }];
    // Remove the no londer present
    NSMutableArray *toRemove = [NSMutableArray array];
    for (SMGridViewItem *item in _visibleItems) {
        if (![addedItems objectForKey:item]) {
            if (item.visible && !item.header) {
                [self queView:item];
            }
            [toRemove addObject:item];
        }
    }
    [_visibleItems removeObjectsInArray:toRemove];
            
    [self handleLoaderDisplay:[self calculateLoadRect:pos delta:self.deltaLoaderView]];
}

- (int)startBucketForRect:(CGRect)loadRect {
    int bucket;
    if (self.vertical) {
        bucket = loadRect.origin.y/kSMdefaultBucketSize;
    } else {
        bucket = loadRect.origin.x/kSMdefaultBucketSize;
    }
    bucket--;
    bucket = MAX(0, bucket);
    return bucket;
}

- (int)endBucketForRect:(CGRect)loadRect {
    int endBucket;
    if (self.vertical) {
        endBucket = (loadRect.origin.y + loadRect.size.height)/kSMdefaultBucketSize;
    } else {
        endBucket = (loadRect.origin.x + loadRect.size.width)/kSMdefaultBucketSize;
    }
    return endBucket;
}

- (void)loadViewsForPos:(float)pos addedIndexes:(NSMutableArray *)addedIndexes {
    if ([_dataSource respondsToSelector:@selector(smGridViewSameSize:)] && [_dataSource smGridViewSameSize:self] && !self.pagingEnabled) {
        [self sameSizeLoadViewsForPos:(NSInteger)pos addedIndexes:addedIndexes];
        return;
    }
    
    [self updateCurrentSection];
    CGRect loadRect = [self calculateLoadRect:pos delta:[self calculateDelta]];
    
    int bucket = [self startBucketForRect:loadRect];
    int endBucket = [self endBucketForRect:loadRect];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (bucket < _bucketItems.count) {
        SMGridViewItem *item = [[_bucketItems objectAtIndex:bucket] objectAtIndex:0];
        indexPath = item.indexPath;
    }

    [self loopItemsStarting:indexPath block:^(SMGridViewItem *item, BOOL *stop) {
#ifdef kSMGridViewDebug
        NSDate *date = [NSDate date];
#endif
        NSIndexPath *indexPath = item.indexPath;
        if ([self isDraggingIndexPath:indexPath] && !item.header) {
            return;
        }
        BOOL visible = item.visible;
        CGRect rect = item.rect;
        if (CGRectIntersectsRect(loadRect, rect) || [self isCurrentHeaderItemSticky:item]) {
            if (!visible) {
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                [self addViewForItem:item];
                [CATransaction commit];
                
                if (addedIndexes && !item.header) {
                    [addedIndexes addObject:indexPath];
                }
            }
        }else {
            if (visible && !item.header) {
                [self queView:item];
            }
        }
        [self updateRectForItem:item];

        for (NSNumber *bucketNum in item.buckets) {
            if (bucketNum.intValue > endBucket) {
                *stop = YES;
            }
        }
#ifdef kSMGridViewDebug
        NSLog(@"loopItem:%f",[date timeIntervalSinceNow]);
#endif
    }];

    [self handleLoaderDisplay:[self calculateLoadRect:pos delta:self.deltaLoaderView]];
}

- (void)loadViewsForCurrentPosAddedIndexes:(NSMutableArray *)addedIndexes {
    if (self.vertical) {
        [self loadViewsForPos:self.contentOffset.y addedIndexes:addedIndexes];
    }else {
        [self loadViewsForPos:self.contentOffset.x addedIndexes:addedIndexes];
    }
}

- (void)loadViewsForCurrentPos {
    [self loadViewsForCurrentPosAddedIndexes:nil];
}

- (void)loadViewsForPos:(NSInteger)x {
    [self loadViewsForPos:x addedIndexes:nil];
}    

- (NSIndexPath *)indexPathForView:(UIView *)view {
    for (NSArray *section in _items) {
        for (SMGridViewItem *item in section) {
            if (item.view == view) {
                return item.indexPath;
            }
        }
    }
    return nil;
}

- (NSInteger)itemsPerRowInSection:(NSInteger)section {
    if ([self numberOfItemsInSection:section] == 0) {
        return 0;
    }
    CGSize size = [_dataSource smGridView:self sizeForIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    if (self.vertical) {
        return floor((self.frame.size.height - self.padding) / (size.height + self.padding));
    }else {
        return floor((self.frame.size.width -self.padding) /(size.width +self.padding));
    }
}


#pragma mark - Paging

- (NSInteger)calculateItemsPerPageInSection:(NSInteger)section {
    return [self numberOfRowsInSection:section] * [self itemsPerRowInSection:section];
}

- (NSInteger)pagingRowForIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row/[self itemsPerRowInSection:indexPath.section]) % [self numberOfRowsInSection:indexPath.section];
}

- (int)calculateNumberOfPagesInSection:(NSInteger)section {
    NSArray *items = [self itemsInSection:section];
    // -1 because of header
    int itemsCount = items.count -1;
    int num = (items.count > 0)?ceil(itemsCount*1.0/[self calculateItemsPerPageInSection:section]):0;
    return num;
}

- (void)calculateNumberOfPages {
    if (self.pagingEnabled) {
        int total = 0;
        for (int section = 0; section < [self numberOfSections]; section++) {
            total += [self calculateNumberOfPagesInSection:section];
        }
        if ([self loaderEnabled]) {
            total++;
        }
        _numberOfPages = total;
    }else {
        _numberOfPages = -1;
    }
}

- (NSInteger)numberOfPages {
    return _numberOfPages;
}

- (BOOL)isFirstOfPage:(NSIndexPath *)indexPath {
    if (self.pagingInverseOrder) {
        return (indexPath.row % [self itemsPerRowInSection:indexPath.section]) == 0;
    }else {
        return (indexPath.row % [self calculateItemsPerPageInSection:indexPath.section]) < [self numberOfRowsInSection:indexPath.section];
    }
}

- (NSInteger)pageForIndexPath:(NSIndexPath *)indexPath {
    return floor(indexPath.row/[self calculateItemsPerPageInSection:indexPath.section]);
}

- (CGPoint)contentOffsetForPage:(NSInteger)page {
    if (self.vertical) {
        CGFloat yValue = page * (self.frame.size.height);
        return CGPointMake(self.contentOffset.x, yValue);
    }else {
        CGFloat xValue = page * (self.frame.size.width);
        return CGPointMake(xValue, self.contentOffset.y);
    }
}

- (NSInteger)findClosestPage:(CGPoint)offset targetContentOffset:(CGPoint)targetContentOffset {
    int numPages = [self numberOfPages];
    float diff = 9999999;
    int page = 0;
    for (int i=0; i < numPages; i++) {
        CGPoint pageOffset = [self contentOffsetForPage:i];
        float tmpDiff = 0;
        if (self.vertical) {
            tmpDiff = ABS(pageOffset.y - offset.y);
        }else {
            tmpDiff = ABS(pageOffset.x - offset.x);
        }
        if (tmpDiff < diff) {
            diff = tmpDiff;
            page = i;
        }
    }
    return page;
}

- (BOOL)pageOutOfBounds:(NSInteger)page {
    return page < 0 || page >= [self numberOfPages];
}

- (void)notifyDelegatePartialPage:(int)page {
    if ([_gridDelegate respondsToSelector:@selector(smGridView:didChangePagePartial:)]) {
        [_gridDelegate smGridView:self didChangePagePartial:page];
    }
}

- (void)setCurrentPage:(NSInteger)page animated:(BOOL)animated {
    if ([self pageOutOfBounds:page]) {
        return;
    }
    if (page != _currentPage) {
        _currentPage = page;
    }
    [self setContentOffset:[self contentOffsetForPage:_currentPage] animated:animated];
}

- (void)setCurrentPage:(NSInteger)page {
    [self setCurrentPage:page animated:YES];
}

- (BOOL)isOffBounds {
    if (self.vertical) {
        return self.contentOffset.y < 0 || self.contentOffset.y > (self.contentSize.height - self.frame.size.height);
    }else {
        return self.contentOffset.x < 0 || self.contentOffset.x > (self.contentSize.width - self.frame.size.width);
    }
}


#pragma mark - Loader

- (BOOL)loaderEnabled {
    return _loaderView && [_dataSource respondsToSelector:@selector(smGridViewShowLoader:)] && [_dataSource smGridViewShowLoader:self];
}

- (void)handleLoaderDisplay:(CGRect)rect {
    if ([self loaderEnabled] && _loaderView && (CGRectContainsRect(rect, _loaderView.frame))) {
        if (!_loaderView.superview) {
            [self addSubview:_loaderView];
            [self sendSubviewToBack:_loaderView];
            if ([_gridDelegate respondsToSelector:@selector(smGridView:didShowLoaderView:)]) {
                [_gridDelegate smGridView:self didShowLoaderView:_loaderView];
            }
        }
    }else if (_loaderView.superview) {
        [_loaderView removeFromSuperview];
        if ([_gridDelegate respondsToSelector:@selector(smGridView:didHideLoaderView:)]) {
            [_gridDelegate smGridView:self didHideLoaderView:_loaderView];
        }
    }
}

- (void)updateLoaderFrame {
    if (_loaderView) {
        CGRect frame = _loaderView.frame;
        if (self.pagingEnabled) {
            CGPoint contentOffset = [self contentOffsetForPage:[self numberOfPages] -1];
            frame.origin = CGPointMake(contentOffset.x + (self.frame.size.width - _loaderView.frame.size.width)/2, contentOffset.y + (self.frame.size.height - _loaderView.frame.size.height)/2);
        }else {
            CGFloat maxValue = [self findMaxValue];
            if (self.vertical) {
                frame.origin = CGPointMake((self.frame.size.width - frame.size.width)/2, maxValue);
            }else {
                frame.origin = CGPointMake(maxValue, (self.frame.size.height - frame.size.height)/2);
            }
        }
        _loaderView.frame = frame;
    }
}

- (void)setLoaderView:(UIView *)loaderView {
    if (loaderView == _loaderView) {
        return;
    }
    [_loaderView removeFromSuperview];
    _loaderView = [loaderView retain];
    [self updateLoaderFrame];
}


#pragma mark - Positon Items
- (void)resetScroll:(BOOL)animated {
    if (self.vertical) {
        [self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top) animated:animated];
    }else {
        [self setContentOffset:CGPointMake(-self.contentInset.left, self.contentOffset.y) animated:animated];
    }
}

- (CGFloat)findMinValueInSectionHeaderAware:(NSInteger)section {
    SMGridViewItem *item = [self headerItemInSection:section];
    return self.vertical ? item.rect.origin.y : item.rect.origin.x;
}

- (CGFloat)findMinValueInSection:(NSInteger)section {
    NSArray *items = [self itemsInSection:section];
    SMGridViewItem *item = [items objectAtIndex:0];
    return (self.vertical ? CGRectGetMinY(item.rect) : CGRectGetMinX(item.rect)) - self.padding;
}

- (CGFloat)findMaxValueInSection:(NSInteger)section {
    if (self.pagingEnabled) {
        return self.numberOfPages * (self.vertical ? self.frame.size.height : self.frame.size.width);
    }
    int maxValue = 0;
    
    NSArray *posArray = [self posArrayInSection:section];
    for (NSNumber *num in posArray) {
        // This is to prevent having empty items and padding
        float numf = num.floatValue;
        if (numf == self.padding) {
            numf = 0;
        }
        maxValue = MAX(maxValue, numf);
    }
    return maxValue;
}

- (CGFloat)findMaxValue {
    NSInteger section = [self numberOfSections] -1;
    if (section >= 0) {
        return [self findMaxValueInSection:section];
    }
    return 0;
}

- (void)updateContentSize {
    CGFloat maxValue = 0;
    if (self.pagingEnabled) {
        if (self.vertical) {
            maxValue = self.frame.size.height + ([self numberOfPages] -1)*(self.frame.size.height);
        }else {
            maxValue = self.frame.size.width + ([self numberOfPages] -1)*(self.frame.size.width);
        }
    }else {
        if ([self loaderEnabled]) {
            maxValue = self.vertical ? CGRectGetMaxY(_loaderView.frame) : CGRectGetMaxX(_loaderView.frame);
        }else {
            maxValue = [self findMaxValue];
        }
    }
    if (self.vertical) {
        maxValue = MAX(self.frame.size.height, maxValue);
        self.contentSize = CGSizeMake(self.frame.size.width, maxValue);
    }else {
        maxValue = MAX(self.frame.size.width, maxValue);
        self.contentSize = CGSizeMake(maxValue, self.frame.size.height);
    }
    [self adjustDraggingViewToFit];
}

- (void)setFrame:(CGRect)frame {
    CGSize size = self.frame.size;
    [super setFrame:frame];
    if (!CGSizeEqualToSize(size, self.frame.size)) {
        if (self.frame.size.height > size.height) {
            [self loadViewsForCurrentPos]; 
        }
        [self updateLoaderFrame];
        [self updateContentSize];
    }
}

- (CGFloat)initialPos {
    return self.padding;
}

- (int)findRowToInsertIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *posArray = [self posArrayInSection:indexPath.section];
    if (self.pagingEnabled && self.pagingInverseOrder) {
        int tmp = [self pagingRowForIndexPath:indexPath];
        return tmp;
    }else {
        CGFloat minValue = 999999;
        int ret = 0;
        int numRows = [self numberOfRowsInSection:indexPath.section];
        for (int i=0; i<numRows; i++) {
            NSNumber *number = nil;
            if (i >= posArray.count) {
                number = [NSNumber numberWithFloat:[self initialPos]];
                [posArray insertObject:number atIndex:i];
            }else {
                number = [posArray objectAtIndex:i];
            }
            CGFloat value = [number floatValue];
            if (value < minValue) {
                minValue = value;
                ret = i;
            }
        }
        return ret;
    }
}

- (void)addItem:(SMGridViewItem *)item toBucket:(int)bucket {
    if (_bucketItems.count - 1 < bucket || _bucketItems.count == 0) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        [items addObject:item];
        [_bucketItems addObject:items];
    }
    else {
        [[_bucketItems objectAtIndex:bucket] addObject:item];
    }
}

- (CGRect)nextBucketForBucket:(int)startingBucket {
    CGRect nextBucket;
    if (self.vertical) {
        nextBucket = CGRectMake(0, (startingBucket+1)*kSMdefaultBucketSize, self.frame.size.width, kSMdefaultBucketSize);
    }
    else {
        nextBucket = CGRectMake((startingBucket+1)*kSMdefaultBucketSize, 0, kSMdefaultBucketSize, self.frame.size.width);
    }
    return nextBucket;
}

- (void)calculateBucketForItem:(SMGridViewItem *)item value:(CGFloat)value {
    int startingBucket = value / kSMdefaultBucketSize;
    
    CGRect nextBucket = [self nextBucketForBucket:startingBucket];
    int i = startingBucket;
    while (CGRectIntersectsRect(nextBucket, item.rect)) {
        i++;
        nextBucket = [self nextBucketForBucket:i];
    }
    int endingBucket = i;
    
    NSMutableArray *allBuckets = [NSMutableArray array];
    for (int i = startingBucket; i <= endingBucket; i++) {
        [self addItem:item toBucket:i];
        [allBuckets addObject:[NSNumber numberWithInt:i]];
    }
    item.buckets = allBuckets;
}

- (CGRect)calculateRectForIndexPath:(NSIndexPath *)indexPath row:(NSInteger)row addIndexPath:(NSIndexPath *)addIndexPath {
    NSMutableArray *posArray = [self posArrayInSection:indexPath.section];
    NSNumber *rowValue = [posArray objectAtIndex:row];
    
    SMGridViewItem *item = [self itemAtIndexPath:indexPath];
    CGRect rect = CGRectZero;
    if (item && !addIndexPath && !item.header) {
        rect = item.rect;
    } else {
        CGSize size = [_dataSource smGridView:self sizeForIndexPath:indexPath];
        rect = CGRectMake(0, 0, size.width, size.height);
    }
    
    
    CGPoint pagingOffset = CGPointZero;
    if (self.pagingEnabled && [self isFirstOfPage:indexPath]) {
        pagingOffset = [self contentOffsetForPage:[self pageForIndexPath:indexPath]];
    }
    
    if (self.vertical) {
        float yValue = CGPointEqualToPoint(CGPointZero, pagingOffset) ? rowValue.floatValue : pagingOffset.y + self.padding;
        rect.origin = CGPointMake(row*(rect.size.width + self.padding) + self.padding, yValue);    
    }else {
        float xValue = CGPointEqualToPoint(CGPointZero, pagingOffset) ? rowValue.floatValue : pagingOffset.x + self.padding;
        rect.origin = CGPointMake(xValue, row*(rect.size.height + self.padding) + self.padding);
    }
    return rect;
}

- (void)updatePosArray:(NSMutableArray *)posArray row:(NSInteger)row item:(SMGridViewItem *)item {
    CGRect rect = item.rect;
    CGFloat value;
    if (self.vertical) {
        value = CGRectGetMaxY(rect) + self.padding;
    }else {
        value = CGRectGetMaxX(rect) + self.padding;
    }
    [posArray replaceObjectAtIndex:row withObject:[NSNumber numberWithFloat:value]];
    [self calculateBucketForItem:item value:value];
}

- (void)loopItems:(void (^)(SMGridViewItem *item))block {
    for (NSArray *section in _items) {
        for (SMGridViewItem *item in section) {
            block(item);
        }
    }
}

- (void)loopItemsStarting:(NSIndexPath *)start block:(void (^)(SMGridViewItem *item, BOOL *stop))block {
    BOOL stop = NO;
    for (int section = start.section; section < [self numberOfSections]; section++) {
        // Always do header
        SMGridViewItem *header = [self headerItemInSection:section];
        block(header, &stop);
        int initialRow = (start.section == section) ? start.row : 0;
        NSArray *items = [self itemsInSection:section];
        for (int row = initialRow; row < items.count; row++) {
            SMGridViewItem *item = [items objectAtIndex:row];
            if (!item.header) {
                block(item, &stop);
            }
            if (stop) {
                return;
            }
        }
    }
}

- (SMGridViewItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _items.count) {
        NSArray *items = [self itemsInSection:indexPath.section];
        if (indexPath.row < items.count) {
            return [items objectAtIndex:indexPath.row];
        }
    }
    return nil;
}

- (NSMutableArray *)itemsInSection:(NSInteger)section {
    if (section < _items.count) {
        return [_items objectAtIndex:section];
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSections {
    if ([_dataSource respondsToSelector:@selector(numberOfSectionsInSMGridView:)]) {
        return [_dataSource numberOfSectionsInSMGridView:self];
    }
    return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(smGridView:numberOfRowsInSection:)]) {
        return [_dataSource smGridView:self numberOfRowsInSection:section];
    } else {
        return numberOfRows;
    }
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [_dataSource smGridView:self numberOfItemsInSection:section];
}

- (SMGridViewItem *)headerItemInSection:(NSInteger)section {
    if (section >= _items.count) {
        return nil;
    }
    NSArray *items = [_items objectAtIndex:section];
    if (items.count > 0) {
        SMGridViewItem *item = [items objectAtIndex:items.count -1];
        if (item.header) {
            return item;
        }
    }
    return nil;
}

- (NSMutableArray *)posArrayInSection:(NSInteger)section {
    for (int s = _posArrays.count; s <= section; s++) {
        [_posArrays addObject:[NSMutableArray array]];
    }
    return [_posArrays objectAtIndex:section];
}

- (void)addHeaderInSection:(NSInteger)section items:(NSMutableArray *)items {
    float firstPos = [[[self posArrayInSection:section] objectAtIndex:0] floatValue];
    CGRect rect = CGRectZero;
    
    if ([_dataSource respondsToSelector:@selector(smGridView:sizeForHeaderInSection:)]) {
        CGSize size = [_dataSource smGridView:self sizeForHeaderInSection:section];
        if (self.vertical) {
            rect = CGRectMake(0, firstPos, self.frame.size.width, size.height);
        } else {
            rect = CGRectMake(firstPos, 0, size.width, self.frame.size.height);
        }
    }
    SMGridViewItem *item = [self headerItemInSection:section];
    if (!item) {
        item = [[[SMGridViewItem alloc] initWithRect:rect] autorelease];
    } else {
        item.rect = rect;
    }
    item.indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    item.header = YES;
    [items addObject:item];
    NSMutableArray *posArray = [self posArrayInSection:section];
    // Update posArray
    for (int i=0; i < posArray.count; i++) {
        [self updatePosArray:posArray row:i item:item];
    }
}

- (NSMutableArray *)createPosArrayForSection:(NSInteger)section {
    NSMutableArray *posArray = [NSMutableArray array];
    int numRows = [self numberOfRowsInSection:section];
    float maxValue = self.padding;
    if (section > 0) {
        maxValue = [self findMaxValueInSection:section-1];
    }
    for (int i = 0; i < numRows; i++) {
        [posArray addObject:[NSNumber numberWithFloat:maxValue]];
    }
    return posArray;
}

- (void)updatePosArrayForSection:(NSInteger)section {
    // Find furthest row in prev
    float value = 0;
    if (section > 0) {
        value = [self findMaxValueInSection:section-1];
    }
    NSMutableArray *posArray = [self posArrayInSection:section];
    [posArray removeAllObjects];
    int numRows = [self numberOfRowsInSection:section];
    for (int i = 0; i < numRows; i++) {
        [posArray addObject:[NSNumber numberWithFloat:value]];
    }
}

- (int)countOfDataSourceInSection:(NSInteger)section {
    return [self numberOfItemsInSection:section];
}

- (NSMutableArray *)updatedItemsAddIndexPath:(NSIndexPath *)addIndexPath section:(NSInteger)section {
    [self updatePosArrayForSection:section];
    NSMutableArray *tmpSectionItems = [NSMutableArray array];
    [self addHeaderInSection:section items:tmpSectionItems];
    int count = [self countOfDataSourceInSection:section];
    NSMutableArray *items = [self itemsInSection:section];
    for (int i = 0; i < count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        int row = [self findRowToInsertIndexPath:indexPath];
        // Number of items -1 because of header
        int itemsCount = (addIndexPath && addIndexPath.section == section) ? items.count : items.count-1;
        SMGridViewItem *item = nil;
        // If we are redispaying an item, we don't want to lose its 'view' property
        if (items && i < itemsCount && ![addIndexPath isEqual:indexPath]) {
            NSInteger origIndex = (addIndexPath && addIndexPath.section == section && i > addIndexPath.row) ? i-1 :i;
            item = [items objectAtIndex:origIndex];
            item.rect = [self calculateRectForIndexPath:[NSIndexPath indexPathForRow:i inSection:section] row:row addIndexPath:addIndexPath];
            item.toAdd = NO;
        }else {
            item = [[[SMGridViewItem alloc] init] autorelease];
            item.rect = [self calculateRectForIndexPath:indexPath row:row addIndexPath:addIndexPath];
            item.toAdd = ([indexPath isEqual:addIndexPath]);
        }
        item.indexPath = indexPath;
        [tmpSectionItems insertObject:item atIndex:i];
        // If we're adding, do not update x value. (Because of animation stuff).
        [self updatePosArray:[self posArrayInSection:section] row:row item:item];
    }
    return tmpSectionItems;
}

- (void)updateExtraViews:(BOOL)updateContentSize {
    [self calculateNumberOfPages];
    [self updateLoaderFrame];
    if (updateContentSize) {
        [self updateContentSize];
    }
    [self updateEmptyView];
}

- (void)updateItemsAddIndexPath:(NSIndexPath *)addIndexPath updateContentSize:(BOOL)updateContentSize {
    NSMutableArray *tmpItems = [[NSMutableArray alloc] init];
    [self resetPosArrays];
    // To track which row to insert
    for (int section = 0; section < [self numberOfSections]; section++) {
        [tmpItems addObject:[self updatedItemsAddIndexPath:addIndexPath section:section]];
    }
    
    [_items release];
    _items = tmpItems;
    [self updateExtraViews:updateContentSize];
}

- (void)updateItemsAddIndexPath:(NSIndexPath *)addIndexPath {
    [self updateItemsAddIndexPath:addIndexPath updateContentSize:YES];
}

- (void)updateItems {
    [self updateItemsAddIndexPath:nil];
}

- (UIView *)viewForIndexPath:(NSIndexPath *)indexPath {
    return [self itemAtIndexPath:indexPath].view;
}

- (void)removeAllViews {
    [self loopItems:^(SMGridViewItem *item) {
        if (item.view) {
            [self queView:item];
        }
    }];
}

- (void)removeAllViewsInSection:(NSInteger)section {
    NSArray *items = [self itemsInSection:section];
    for (SMGridViewItem *item in items) {
        if (item.view) {
            [self queView:item];
        }
    }
}

- (BOOL)hasItems {
    for (NSArray *items in _items) {
        for (SMGridViewItem *item in items) {
            if (!item.header) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)resetPosArrays {
    NSMutableArray *tmp = [NSMutableArray array];
    for (int section = 0; section < [self numberOfSections]; section++) {
        [tmp addObject:[NSMutableArray array]];
    }
    self.posArrays = tmp;
}

- (void)resetItemsInSection:(NSInteger)section {
    [[self itemsInSection:section] removeAllObjects];
}

- (void)reloadSection:(NSInteger)section {
    if ((_enableSort && _items) || self.busy) {
        return;
    }
    if (!_items) {
        [self reloadData];
        return;
    }
    _reloadingData = YES;
    [self removeAllViewsInSection:section];
    [self resetItemsInSection:section];
    // Update all following sectsions
    for (int i = section; i < [self numberOfSections]; i++) {
        [_items replaceObjectAtIndex:i withObject:[self updatedItemsAddIndexPath:nil section:i]];
    }
    _reloadingData = NO;
    [self updateExtraViews:YES];
    [self loadViewsForCurrentPos];
}


- (void)reloadSectionOnlyNew:(NSInteger)section {
    if ((_enableSort && _items) || self.busy) {
        return;
    }
    if (!_items) {
        [self reloadData];
        return;
    }
    [self checkCorrectArrays];
    NSMutableArray *items = [self itemsInSection:section];    
    if (items.count == 0) {
        [self resetPosArrays];
        [self reloadSection:section];
        return;
    }
    _reloadingData = YES;
        
    int count = [self numberOfItemsInSection:section];
    // -1 because of header
    for (int i = items.count -1; i < count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
        int row = [self findRowToInsertIndexPath:indexPath];
        SMGridViewItem *item = [[[SMGridViewItem alloc] init] autorelease];
        item.rect = [self calculateRectForIndexPath:indexPath row:row addIndexPath:nil];
        item.indexPath = indexPath;
        [items insertObject:item atIndex:i];
        NSMutableArray *posArray = [self posArrayInSection:section];
        [self updatePosArray:posArray row:row item:item];
    }

    [self updateExtraViews:YES];
    _reloadingData = NO;
    [self loadViewsForCurrentPos];
}

- (void)reloadDataWithPage:(NSInteger)page {
    if ((_enableSort && _items) || self.busy) {
        return;
    }
    [self resetPosArrays];
    _reloadingData = YES;
    [self removeAllViews];
    [_items release];
    _items = nil;
    [self updateItems];
    if (page >= 0) {
        CGPoint offset = [self contentOffsetForPage:page];
        [self setContentOffset:offset animated:NO];
    }
    _reloadingData = NO;
    [self loadViewsForCurrentPos];
}

- (void)reloadData {
#ifdef kSMGridViewDebug
    NSDate *date = [NSDate date];
#endif
    [self reloadDataWithPage:-1];
#ifdef kSMGridViewDebug
    NSLog(@"reloadData:%f",[date timeIntervalSinceNow]);
#endif
}

- (void)checkCorrectArrays {
    for (int i = 0; i < [self numberOfSections] - _items.count; i++) {
        [_items addObject:[NSMutableArray array]];
    }
}

// Special method to do fast infinite scrolling
- (void)reloadDataOnlyNew {
    if ([self numberOfSections] > 0) {
        [self reloadSectionOnlyNew:[self numberOfSections]-1];
    } else {
        [self reloadData]; 
    }
}

- (NSArray *)currentViews:(BOOL)includeHeaders {
    NSMutableArray *ret = [NSMutableArray array];
    [self loopItems:^(SMGridViewItem *item) {
        if ((!item.header || includeHeaders) && item.view) {
            [ret addObject:item.view];
        }
    }];
    [ret addObjectsFromArray:_reusableViews];
    return ret;
}

- (NSArray *)currentViews {
    return [self currentViews:NO];
}

- (UIView *)headerViewForSection:(NSInteger)section {
    return [self headerItemInSection:section].view;
}

#pragma mark - Adding/Removing items

- (void)scrollToRectHeaderAware:(CGRect)rect animated:(BOOL)animated {
    UIView *header = [self headerViewForSection:[self currentSection]];
    if (header) {
        if (self.vertical) {
            rect.origin = CGPointMake(rect.origin.x, rect.origin.y - header.frame.size.height);
        } else {
            rect.origin = CGPointMake(rect.origin.x - header.frame.size.width, rect.origin.y);
        }
    }
    [self scrollRectToVisible:rect animated:animated];
}

- (CGRect)visibleRectHeaderAware {
    CGRect visibleRect = visibleRect = CGRectMake(self.contentOffset.x, self.contentOffset.y, self.frame.size.width, self.frame.size.height);
    UIView *header = [self headerViewForSection:[self currentSection]];
    if (header) {
        if (self.vertical) {
            visibleRect.origin = CGPointMake(visibleRect.origin.x,
                                             visibleRect.origin.y + header.frame.size.height);
            visibleRect.size = CGSizeMake(visibleRect.size.width,
                                          visibleRect.size.height - header.frame.size.height);
        } else {
            visibleRect.origin = CGPointMake(visibleRect.origin.x + header.frame.size.width,
                                             visibleRect.origin.y);
            visibleRect.size = CGSizeMake(visibleRect.size.width - header.frame.size.width,
                                          visibleRect.size.height);
        }
    }
    return visibleRect;
}

- (BOOL)rectIsVisible:(CGRect)rect {
    CGRect visibleRect = [self visibleRectHeaderAware];
    return (CGRectContainsRect(visibleRect, rect));
}

- (BOOL)isLastIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == _items.count && indexPath.row == [[_items objectAtIndex:indexPath.section] count] -1;
}

- (void)finishAddingIndexPath:(NSIndexPath *)indexPath {
    [indexPath retain];
    self.addingIndexPath = nil;
    [self updateItemsAddIndexPath:indexPath];
    BOOL shouldAnimateOthers = ![self isLastIndexPath:indexPath];
    [UIView animateWithDuration:shouldAnimateOthers?kSMTVanimDuration:0 delay:0 options:0 animations:^(void) {
        [self loadViewsForCurrentPos];
        SMGridViewItem *item = [self itemAtIndexPath:indexPath];
        item.view.hidden = YES;
    } completion:^(BOOL finished) {
        SMGridViewItem *item = [self itemAtIndexPath:indexPath];
        item.view.alpha = 0.0;
        item.view.hidden = NO;
        [UIView animateWithDuration:kSMTVanimDuration delay:0 options:0 animations:^(void) {
            item.view.alpha = 1.0;
        } completion:^(BOOL finished) {
            item.toAdd = NO;
            if ([_gridDelegate respondsToSelector:@selector(smGrid:didFinishAddingIndexPath:)]) {
                [_gridDelegate smGridView:self didFinishAddingIndexPath:indexPath];
            }
            _addingOrRemoving = NO;
            [indexPath release];
        }];
    }];
}

- (void)addItemAtIndexPath:(NSIndexPath *)indexPath {
    [self addItemAtIndexPath:indexPath scroll:YES];
}

- (void)addItemAtIndexPath:(NSIndexPath *)indexPath scroll:(BOOL)scroll {
    if (_addingOrRemoving) {
        return;
    }
    _addingOrRemoving = YES;
    self.addingIndexPath = indexPath;
    if (self.pagingEnabled) {
        CGPoint offset = [self contentOffsetForPage:[self pageForIndexPath:indexPath]];
        if (CGPointEqualToPoint(offset, self.contentOffset)) {
            [self finishAddingIndexPath:indexPath];
        }else {
            self.addingIndexPath = indexPath;
            [self setContentOffset:offset animated:YES];
        }
    }else {
        SMGridViewItem *item = [self itemAtIndexPath:indexPath];
        // Center scroll
        CGRect rect = item.rect;
        if (self.vertical) {
            rect.origin.y = rect.origin.y - (self.frame.size.height - rect.size.height)/2;
            if (rect.origin.y + self.frame.size.height > (self.contentSize.height + rect.size.height)) {
                rect.origin.y = self.contentSize.height - self.frame.size.height;
            }
            if (CGRectGetMinY(rect) < 0) {
                rect.origin.y = 0;
            }
            if (self.contentOffset.y == rect.origin.y || !scroll) {
                [self finishAddingIndexPath:indexPath];
            }else {
                self.addingIndexPath = indexPath;
                [self setContentOffset:CGPointMake(self.contentOffset.x, rect.origin.y) animated:YES];
            }
        }else {
            rect.origin.x = rect.origin.x - (self.frame.size.width - rect.size.width)/2;
            if (rect.origin.x + self.frame.size.width > (self.contentSize.width + rect.size.width)) {
                rect.origin.x = self.contentSize.width - self.frame.size.width;
            }
            if (CGRectGetMinX(rect) < 0) {
                rect.origin.x = 0;
            }
            if (self.contentOffset.x == rect.origin.x || !scroll) {
                [self finishAddingIndexPath:indexPath];
            }else {
                self.addingIndexPath = indexPath;
                [self setContentOffset:CGPointMake(rect.origin.x, self.contentOffset.y) animated:YES];
            }
        }
    }
}

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _items.count) {
        NSMutableArray *items = [_items objectAtIndex:indexPath.section];
        if (indexPath.row < items.count) {
            [items removeObjectAtIndex:indexPath.row];
        }
    }
}

- (void)finishRemovingIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *addedIndexes = [NSMutableArray array];
    SMGridViewItem *item = [self itemAtIndexPath:indexPath];
    [UIView animateWithDuration:kSMTVanimDuration delay:0 options:0 animations:^(void) {
        item.view.alpha = 0.0;
        item.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        [item.view removeFromSuperview];
        item.view = nil;
        if ([_dataSource respondsToSelector:@selector(smGridView:performRemoveIndexPath:)]) {
            [_dataSource smGridView:self performRemoveIndexPath:indexPath];
        }
        [self deleteItemAtIndexPath:indexPath];
        [self updateItemsAddIndexPath:nil updateContentSize:NO];
        [UIView animateWithDuration:kSMTVanimDuration delay:0 options:0 animations:^(void) {
            [self loadViewsForCurrentPosAddedIndexes:addedIndexes];
            [self updateContentSize];
            for (NSIndexPath *addedIndexPath in addedIndexes) {
                SMGridViewItem *item = [self itemAtIndexPath:addedIndexPath];
                item.view.hidden = YES;
            }
        } completion:^(BOOL finished) {
            // We need this extra load to prevent issues with animating contentSize
            [self loadViewsForCurrentPosAddedIndexes:addedIndexes];
            for (NSIndexPath *addedIndexPath in addedIndexes) {
                SMGridViewItem *item = [self itemAtIndexPath:addedIndexPath];
                item.view.hidden = NO;
            }
            if ([_gridDelegate respondsToSelector:@selector(smGridView:didFinishRemovingIndexPath:)]) {
                [_gridDelegate smGridView:self didFinishRemovingIndexPath:indexPath];
            }
            _addingOrRemoving = NO;
        }];
    }];
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath {
    [self removeItemAtIndexPath:indexPath scroll:YES];
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath scroll:(BOOL)scroll {
    if (_addingOrRemoving || (indexPath.row == _draggingOrigItemsIndex && indexPath.section == _draggingSection)) {
        return;
    }
    if (_addingOrRemoving) {
        return;
    }
    _addingOrRemoving = YES;
    if (self.pagingEnabled) {
        CGPoint offset = [self contentOffsetForPage:[self pageForIndexPath:indexPath]];
        if (CGPointEqualToPoint(offset, self.contentOffset) || !scroll) {
            [self finishRemovingIndexPath:indexPath];
        }else {
            self.removingIndexPath = indexPath;
            [self setContentOffset:offset animated:YES];
        }
    }else {
        SMGridViewItem *item = [self itemAtIndexPath:indexPath];
        if ([self rectIsVisible:item.rect] || !scroll) {
            [self finishRemovingIndexPath:indexPath];
        }else {
            self.removingIndexPath = indexPath;
//            [self scrollRectToVisible:item.rect animated:YES];
            [self scrollToRectHeaderAware:item.rect animated:YES];
        }
    }
} 

- (CGRect)rectForSection:(NSInteger)section {
    float max = [self findMaxValueInSection:section];
    float min = [self findMinValueInSection:section];
    if (self.vertical) {
        return CGRectMake(0, min, self.frame.size.width, max - min);
    } else {
        return CGRectMake(min, 0, max - min, self.frame.size.height);
    }
}


#pragma mark - EmptyView

- (int)totalItemsCountNoHeader {
    int ret = 0;
    for (NSArray *items in _items) {
        for (SMGridViewItem *item in items) {
            if (!item.header) {
                ret++;
            }
        }
    }
    return ret;
}

- (void)setEmptyView:(UIView *)emptyView {
    if (emptyView == _emptyView) {
        return;
    }
    
    [_emptyView removeFromSuperview];
    _emptyView = [emptyView retain];
    [self updateEmptyView];
}

- (void)updateEmptyView {
    if (_emptyView && [self totalItemsCountNoHeader] <= 0 && ![self loaderEnabled]) {
        if (!_emptyView.superview) {
            CGRect frame = _emptyView.frame;
            frame.origin = CGPointMake((self.frame.size.width - _emptyView.frame.size.width)/2, (self.frame.size.height - _emptyView.frame.size.height)/2);
            _emptyView.frame = frame;
            [self addSubview:_emptyView];
        }
    }else {
        if (_emptyView.superview) {
            [_emptyView removeFromSuperview];
        }
    }
}

- (void)updateContentInset:(UIEdgeInsets)contentInset animated:(BOOL)animated {
    CGFloat duration = animated?0.3:0;
    [UIView animateWithDuration:duration animations:^{
        self.contentInset = contentInset;
    }];
}


#pragma mark - Sorting

- (void)addSorting:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *)view;
        if ([control actionsForTarget:self forControlEvent:UIControlEventTouchDragInside].count == 0) {
            [control addTarget:self action:@selector(dragInside:withEvent:) forControlEvents:UIControlEventTouchDragInside];
            [control addTarget:self action:@selector(touchUp:withEvent:) forControlEvents:UIControlEventTouchDragOutside];
            [control addTarget:self action:@selector(touchUp:withEvent:) forControlEvents:UIControlEventTouchDragExit];
        }
        if ([control actionsForTarget:self forControlEvent:UIControlEventTouchDown].count == 0) {
            [control addTarget:self action:@selector(touchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        }
        if ([control actionsForTarget:self forControlEvent:UIControlEventTouchUpInside].count == 0) {
            [control addTarget:self action:@selector(touchUp:withEvent:) forControlEvents:UIControlEventTouchUpInside];
            [control addTarget:self action:@selector(touchUp:withEvent:) forControlEvents:UIControlEventTouchUpOutside];
            [control addTarget:self action:@selector(touchUp:withEvent:) forControlEvents:UIControlEventTouchCancel];
        }
    }
}

- (void)touchDown:(UIControl *)controlView withLocationInView:(CGPoint)point {
    _draggingPoint = point;
    self.draggingView = controlView;
    NSIndexPath *indexPath = [self indexPathForView:controlView];
    _draggingSection = indexPath.section;
    _draggingItemsIndex = indexPath.row;
    _draggingOrigItemsIndex = _draggingItemsIndex;
    if ([_gridDelegate respondsToSelector:@selector(smGridView:startDraggingView:atIndex:)]) {
        [_gridDelegate smGridView:self startDraggingView:_draggingView atIndex:_draggingItemsIndex];
    }
    [self bringSubviewToFront:_draggingView];
}

- (void)touchDown:(UIControl *)controlView withEvent:(UIEvent *)event {
    if (!_enableSort || [event allTouches].count > 1 || _draggingView) {
        return;
    }
    if ([_dataSource respondsToSelector:@selector(smGridView:canMoveItemAtIndexPath:)]) {
        if (![_dataSource smGridView:self canMoveItemAtIndexPath:[self indexPathForView:controlView]]) {
            return;
        }
    }
    [self touchDown:controlView withLocationInView:[[[event allTouches] anyObject] locationInView:controlView]];
}

- (void)touchUp:(UIControl *)controlView withEvent:(UIEvent *)event {
    if (controlView != _draggingView) {
        return;
    }
    if ([_gridDelegate respondsToSelector:@selector(smGridView:stopDraggingView:atIndex:)]) {
        [_gridDelegate smGridView:self stopDraggingView:_draggingView atIndex:_draggingOrigItemsIndex];
    }
    [self.dragAnimTimer invalidate];
    self.dragAnimTimer = nil;
    [self.dragPageAnimTimer invalidate];
    self.dragPageAnimTimer = nil;
    [self.dragStartAnimTimer invalidate];
    self.dragStartAnimTimer = nil;
    NSArray *items = [self itemsInSection:_draggingSection];
    [UIView animateWithDuration:0.2 animations:^{
        SMGridViewItem *item = [items objectAtIndex:_draggingItemsIndex];
        controlView.frame = item.rect;
        if (self.pagingEnabled) {
            [self setContentOffset:[self contentOffsetForPage:[self pageForIndexPath:item.indexPath]] animated:YES];
        } else {
            [self scrollRectToVisible:controlView.frame animated:YES];
        }
    } completion:^(BOOL finished) {
        if (_draggingItemsIndex != _draggingOrigItemsIndex && _draggingItemsIndex >= 0) {
            if ([_dataSource respondsToSelector:@selector(smGridView:shouldMoveItemFrom:to:)]) {
                [_dataSource smGridView:self shouldMoveItemFrom:[NSIndexPath indexPathForRow:_draggingOrigItemsIndex inSection:_draggingSection] to:[NSIndexPath indexPathForRow:_draggingItemsIndex inSection:_draggingSection]];
            }
        }
        [self sendSubviewToBack:self.draggingView];
        _draggingSection = -1;
        _draggingOrigItemsIndex = -1;
        _draggingItemsIndex = -1;
        self.draggingView = nil;
    }];
}

- (int)findDraggingPosition:(UIControl *)controlView {
    float retDistance = FLT_MAX;
    int ret = -1;
    int i = 0;
    NSArray *items = [self itemsInSection:_draggingSection];
    if (_draggingOrigItemsIndex >= items.count) {
        return _draggingOrigItemsIndex;
    }
    float currentDistance = CGPointDistance(controlView.center, [[items objectAtIndex:_draggingItemsIndex] centerPoint]);
    for (SMGridViewItem *item in items) {
        if (!item.header) {
            float distance = CGPointDistance(controlView.center,item.centerPoint);
            if (distance < retDistance && distance < currentDistance -20) {
                retDistance = distance;
                ret = i;
            }
        }
        i++;
    }
    return ret;
}

- (CGRect)draggingAnimRectForSection:(NSInteger)section {
    float max = [self findMaxValueInSection:section];
    float min = [self findMinValueInSectionHeaderAware:section];
    if (self.vertical) {
        return CGRectMake(0, min, self.frame.size.width, max - min);
    } else {
        return CGRectMake(min, 0, max - min, self.frame.size.height);
    }
}

- (void)moveEnd {
    CGRect rect = [self draggingAnimRectForSection:_draggingSection];
    float pxMove = [self calculateDraggingPxMove];
    if (self.vertical) {
        if (self.contentOffset.y <= CGRectGetMaxY(rect) - _draggingView.frame.size.height - self.contentInset.top) {
            [self setContentOffset:CGPointMake(0, self.contentOffset.y + pxMove) animated:NO];
            
            [self calculatePositionsDragTimer];
        } 
    } else {
        if (self.contentOffset.x <= CGRectGetMaxX(rect) - _draggingView.frame.size.width - self.contentInset.left) {
            [self setContentOffset:CGPointMake(self.contentOffset.x + pxMove, 0) animated:NO];
            
            [self calculatePositionsDragTimer];
        }
    }
}

- (void)moveStart {
    CGRect rect = [self draggingAnimRectForSection:_draggingSection];
    float pxMove = [self calculateDraggingPxMove];
    if (self.vertical) {
        if (self.contentOffset.y + self.contentInset.top > CGRectGetMinY(rect)) {
            [self setContentOffset:CGPointMake(0, self.contentOffset.y - pxMove) animated:NO];
            
            [self calculatePositionsDragTimer];
        }
    } else {
        if (self.contentOffset.x + self.contentInset.left > CGRectGetMinY(rect)) {
            [self setContentOffset:CGPointMake(self.contentOffset.x - pxMove, 0) animated:NO];
            
            [self calculatePositionsDragTimer];
        }
    }
}

- (SMGridViewSortAnimSpeed)calculateDraggingSpeedWithGap:(float)gap {
    if (gap < 10) {
        return SMGridViewSortAnimSpeedFast;
    } else if (gap < 50) {
        return SMGridViewSortAnimSpeedMid;
    } else {
        return SMGridViewSortAnimSpeedSlow;
    }
}

- (float)calculateDraggingInterval {
    switch (_draggingSpeed) {
        case SMGridViewSortAnimSpeedFast:
            return 0.01;
        case SMGridViewSortAnimSpeedMid:
            return 0.01;
        case SMGridViewSortAnimSpeedSlow:
        default:
            return 0.01;
    }
}

- (float)calculateDraggingPxMove {
    switch (_draggingSpeed) {
        case SMGridViewSortAnimSpeedFast:
            return 8;
        case SMGridViewSortAnimSpeedMid:
            return 3;
        case SMGridViewSortAnimSpeedSlow:
        default:
            return 1;
    }
}

- (void)changePage:(NSTimer *)timer {
    int newPage = [[timer.userInfo objectForKey:@"newPage"] intValue];
    BOOL next = newPage > _currentPage;
    [self setCurrentPage:newPage animated:YES];
    [self changePageTimer:next interval:1];
}

- (void)changePageTimer:(BOOL)next interval:(NSTimeInterval)interval {
    int newPage = next? self.currentPage+1 : self.currentPage-1;
    if ([self pageOutOfBounds:newPage]) {
        return;
    }
    NSNumber *timerPage = nil;
    if (self.dragPageAnimTimer.isValid) {
        [self.dragPageAnimTimer.userInfo objectForKey:@"newPage"];
    }
    if (!timerPage || timerPage.intValue != newPage) {
        [self.dragPageAnimTimer invalidate];
        self.dragPageAnimTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(changePage:) userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:newPage] forKey:@"newPage"] repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.dragPageAnimTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)handleScrollAnimation {
    float distanceToEnd = 0;
    float distanceToStart = 0;
    if (self.vertical) {
        distanceToEnd  = self.frame.size.height -_draggingView.center.y + self.contentOffset.y;
        distanceToStart  = _draggingView.center.y - self.contentOffset.y;
    } else {
        distanceToEnd  = self.frame.size.width -_draggingView.center.x + self.contentOffset.x;
        distanceToStart  = _draggingView.center.x - self.contentOffset.x;
    }
    if (distanceToEnd < 100) {
        if (self.pagingEnabled) {
            [self changePageTimer:YES interval:.5];
        } else {
            SMGridViewSortAnimSpeed newSpeed = [self calculateDraggingSpeedWithGap:distanceToEnd];
            if (_draggingSpeed != newSpeed) {
                _draggingSpeed = newSpeed;
                [self.dragAnimTimer invalidate];
                self.dragAnimTimer = [NSTimer timerWithTimeInterval:[self calculateDraggingInterval] target:self selector:@selector(moveEnd) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.dragAnimTimer forMode:NSRunLoopCommonModes];
                [self.dragAnimTimer fire];
            }
        }
        
    } else if (distanceToStart < 100) {
        if (self.pagingEnabled) {
            [self changePageTimer:NO interval:.5];
        } else {
            SMGridViewSortAnimSpeed newSpeed = [self calculateDraggingSpeedWithGap:distanceToStart];
            if (_draggingSpeed != newSpeed) {
                _draggingSpeed = newSpeed;
                [self.dragAnimTimer invalidate];
                self.dragAnimTimer = [NSTimer timerWithTimeInterval:[self calculateDraggingInterval] target:self selector:@selector(moveStart) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.dragAnimTimer forMode:NSRunLoopCommonModes];
                [self.dragAnimTimer fire];
            }
        }
    } else {
        _draggingSpeed = SMGridViewSortAnimSpeedNone;
        [self.dragAnimTimer invalidate];
        self.dragAnimTimer = nil;
        [self.dragPageAnimTimer invalidate];
        self.dragPageAnimTimer = nil;
    }
}

- (void)calculatePositionsDrag {
    if (_addingOrRemoving) {
        return;
    }
    int newPos = [self findDraggingPosition:_draggingView];
    NSMutableArray *items = [self itemsInSection:_draggingSection];
    if (newPos != _draggingItemsIndex && newPos >= 0 && newPos < items.count) {
        SMGridViewItem *item = [[items objectAtIndex:_draggingItemsIndex] retain];
        [items removeObjectAtIndex:_draggingItemsIndex];
        [items insertObject:item atIndex:newPos];
        [item release];
        _draggingItemsIndex = newPos;
        [self updateItems];
        [UIView animateWithDuration:0.2 animations:^{
            [self loadViewsForCurrentPos];
        }];
    } else {
        // Check if we need to change pages
        if (self.pagingEnabled) {
            
        }
    }
}

- (void)adjustDraggingViewToFit {
    if (_draggingView) {
        _draggingView.center = [self adjustDragPointToFit:_draggingView.center controlView:_draggingView];
    }
}

- (CGPoint)adjustDragPointToFit:(CGPoint)point controlView:(UIControl *)controlView {
    CGRect sectionRect = [self rectForSection:_draggingSection];
    
    float minY = CGRectGetMinY(sectionRect) + controlView.frame.size.height/2;
    float maxY = CGRectGetMaxY(sectionRect) - controlView.frame.size.height/2;
    float minX = CGRectGetMinX(sectionRect) + controlView.frame.size.width/2;
    float maxX = CGRectGetMaxX(sectionRect) - controlView.frame.size.width/2;
    
    
    if (point.x > maxX) point.x = maxX;
    if (point.x < minX) point.x = minX;
    if (point.y > maxY) point.y = maxY;
    if (point.y < minY) point.y = minY;
    
    return point;
}

- (void)calculatePositionsDragTimer {
    [self.dragStartAnimTimer invalidate];
    if (_sortWaitBeforeAnimate > 0) {
        self.dragStartAnimTimer = [NSTimer timerWithTimeInterval:_sortWaitBeforeAnimate target:self selector:@selector(calculatePositionsDrag) userInfo:nil repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.dragStartAnimTimer forMode:NSRunLoopCommonModes];
    } else {
        [self calculatePositionsDrag];
    }
}

- (void)dragInside:(UIControl *)controlView withEvent:(UIEvent *)event {
    if (controlView != _draggingView || !_enableSort || event.allTouches.count > 1) {
        return;
    }
    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
    point.x += controlView.frame.size.width/2 - _draggingPoint.x;
    point.y += controlView.frame.size.height/2 - _draggingPoint.y;
    
    [self bringSubviewToFront:controlView];
    
    point = [self adjustDragPointToFit:point controlView:controlView];
    if (!CGPointEqualToPoint(point, controlView.center)) {
        controlView.center = point;
        [self calculatePositionsDragTimer];
        [self handleScrollAnimation];
    }
}

- (void)setEnableSort:(BOOL)enableSort {
    NSArray *items = [self itemsInSection:_draggingSection];
    if (_enableSort && !enableSort) {
        if (_draggingView && _draggingOrigItemsIndex < _items.count) {
            _draggingView.frame = [[items objectAtIndex:_draggingOrigItemsIndex] rect];
        }
        self.draggingView = nil;
        _draggingOrigItemsIndex = -1;
        _draggingItemsIndex = -1;
    }
    _enableSort = enableSort;
}

- (BOOL)busy {
    return _addingOrRemoving || _draggingView != nil;
}

- (void)adjustDraggingViewToOffset {
    if (_draggingView) {
        CGPoint center;
        if (self.vertical) {
            center = CGPointMake(_draggingView.center.x, _draggingView.center.y + self.contentOffset.y - _lastOffset.y);
        } else {
            center = CGPointMake(_draggingView.center.x + self.contentOffset.x - _lastOffset.x, _draggingView.center.y);
        }
        _draggingView.center = [self adjustDragPointToFit:center controlView:_draggingView];
    }
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(scrollViewDidScroll:)] && _gridDelegate != (id)self) {
        [_gridDelegate scrollViewDidScroll:scrollView];
    }
    if (!_reloadingData) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self loadViewsForCurrentPos];
        [CATransaction commit];
    }
    int page = [self findClosestPage:self.contentOffset targetContentOffset:CGPointZero];
    if (page != _currentPage) {
        _currentPage = page;
        [self notifyDelegatePartialPage:_currentPage];
    }

    [self adjustDraggingViewToOffset];
    _lastOffset = self.contentOffset;
    
    if (self.vertical) {
        if (self.pagingEnabled && [self contentOffsetForPage:_currentPage].y == scrollView.contentOffset.y && (_currentOffsetPage != _currentPage)) {
            _currentOffsetPage = _currentPage;
            if (_gridDelegate && [_gridDelegate respondsToSelector:@selector(smGridView:didChangePage:)]) {
                [_gridDelegate smGridView:self didChangePage:_currentPage];
            }
        }
    }
    else {
        if (self.pagingEnabled && [self contentOffsetForPage:_currentPage].x == scrollView.contentOffset.x && (_currentOffsetPage != _currentPage)) {
            _currentOffsetPage = _currentPage;
            if (_gridDelegate && [_gridDelegate respondsToSelector:@selector(smGridView:didChangePage:)]) {
                [_gridDelegate smGridView:self didChangePage:_currentPage];
            }
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)] && _gridDelegate != (id)self) {
        [_gridDelegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    if ([_gridDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]  && _gridDelegate != (id)self) {
        [_gridDelegate scrollViewWillEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([_gridDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]  && (id)_gridDelegate != self) {
        [_gridDelegate scrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]  && _gridDelegate != (id)self) {
        [_gridDelegate scrollViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([_gridDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)] && _gridDelegate != (id)self) {
        [_gridDelegate scrollViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.addingIndexPath) {
        [self finishAddingIndexPath:self.addingIndexPath];
        self.addingIndexPath = nil;
    } else if (self.removingIndexPath) {
        [self finishRemovingIndexPath:self.removingIndexPath];
        self.removingIndexPath = nil;
    }
    
    if ([_gridDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [_gridDelegate scrollViewDidEndScrollingAnimation:self];
    }
}

@end
