//
//  SMGridView.h
//  SMGridView
//
//  Created by Miguel Cohnen and Sarah Lensing on 28/10/11.
//

#import <UIKit/UIKit.h>

@class SMGridView;

/**
 Implement this protocol to provide an SMGridView with data to create the views. 
 */
@protocol SMGridViewDataSource <NSObject>

/**
 @return Number of items in a section
 @param gridView The calling SMGridView
 @param section The asked section
 */
- (NSInteger)smGridView:(SMGridView *)gridView numberOfItemsInSection:(NSInteger)section;

/**
 @return Size of a view in a given indexPath
 @param gridView The calling SMGridView
 @param indexPath The target indexPath
 */
- (CGSize)smGridView:(SMGridView *)gridView sizeForIndexPath:(NSIndexPath *)indexPath;

/**
 You should use dequeReusableView or dequeReusableViewWithClass: inside this method for better performance
 
 @return Size of a view in a given indexPath
 @param gridView The calling SMGridView
 @param indexPath The target indexPath
 */
- (UIView *)smGridView:(SMGridView *)gridView viewForIndexPath:(NSIndexPath *)indexPath;


@optional

/**
 Use this method if your sections contain different number of rows. Otherwise you can use numberOfRows property
 
 @return number of rows in a section
 @param gridView The calling SMGridView
 @param section The target section
 */
- (NSInteger)smGridView:(SMGridView *)gridView numberOfRowsInSection:(NSInteger)section;

/**
 This method will be called when the user sorts the grid. DataSource should update its data accordingly
 
 @param gridView The calling SMGridView
 @param fromIndexPath The original indexPath
 @param toIndexPath The new indexPath
 */
- (void)smGridView:(SMGridView *)gridView shouldMoveItemFrom:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)toIndexPath;

/**
 This method will be called when a remove animation is finished. `SMGridViewDataSource` should remove the item at indexPath position in the implementation of this method
 
 @param gridView The calling SMGridView
 @param indexPath The indexPath to delete
 */
- (void)smGridView:(SMGridView *)gridView performRemoveIndexPath:(NSIndexPath *)indexPath;

/**
 Use this method to decide wether to show a loader or not. Typically you make your `SMGridViewDataSource` manage this method and returning `YES`or `NO` if it is loading more content.
 
 @param gridView The calling SMGridView
 @return Wether to show or not the loader
 */
- (BOOL)smGridViewShowLoader:(SMGridView *)gridView;

/**
 This is being called whenever a view is queued. Use this to stop animations, clean...
 
 @param gridView The calling SMGridView
 @param view The view that is about to be queued
 */
- (void)smGridView:(SMGridView *)gridView willQueueView:(UIView *)view;

/**
 Return yes in this method if all your views have the same size. This will have a big improvement in performance
 
 @param gridView The calling SMGridView
 */
- (BOOL)smGridViewSameSize:(SMGridView *)gridView;

/**
 Implement this method if your SMGridView has more than 1 section. No need to implement if it only has 1 section
 
 @param gridView The calling SMGridView
 @return The number of sections in the grid
 */
- (NSInteger)numberOfSectionsInSMGridView:(SMGridView *)gridView;

/**
 Implement this method if you want to have header views for your section
 
 @param gridView The calling SMGridView
 @param section The target section
 @return The size of the header in the given section. Return CGSizeZero if no header
 */
- (CGSize)smGridView:(SMGridView *)gridView sizeForHeaderInSection:(NSInteger)section;

/**
 Implement this method if you want to have header views for your section
 
 @param gridView The calling SMGridView
 @param section The target section
 @return The header view for a given section. Return nil if no header.
 */
- (UIView *)smGridView:(SMGridView *)gridView viewForHeaderInSection:(NSInteger)section;

/**
 Implement this method in combination with property [SMGridView enableSort] to be able to move items
 
 @param gridView The calling SMGridView
 @param indexPath The indexPath of the item that is about to be dragged
 @return `YES` if an item at the given indexPath can be moved.
 */
- (BOOL)smGridView:(SMGridView *)gridView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
@end


/**
 Implement This protocol to get notified about certain behaviors of the SMGridView.
 **Important:** This object will be used as the origin UIScrollViewDelegate. Never set the property delegate of UIScrollView of a SMGridView, use instead the property [SMGridView gridDelegate]
 */
@protocol SMGridViewDelegate <UIScrollViewDelegate>
@optional

/**
 Called once a new view has been added to the view as a result to a call to [SMGridView addItemAtIndexPath:]
 
 @param gridView The calling SMGridView
 @param indexPath The added indexPath
 */
- (void)smGridView:(SMGridView *)gridView didFinishAddingIndexPath:(NSIndexPath *)indexPath;

/**
 Called once a view has been removed as a result to a call to [SMGridView removeItemAtIndexPath:]
 
 @param gridView The calling SMGridView
 @param indexPath The added indexPath
 */
- (void)smGridView:(SMGridView *)gridView didFinishRemovingIndexPath:(NSIndexPath *)indexPath;

/**
 Called when property pagingEnabled is YES and a page changes and the grid stops moving
 
 @param gridView The calling SMGridView
 @param page The new page
 */
- (void)smGridView:(SMGridView *)gridView didChangePage:(NSInteger)page;

/**
 Called when property pagingEnabled is YES and a new page is more visible than the former current page
 
 @param gridView The calling SMGridView
 @param page The new page
 */
- (void)smGridView:(SMGridView *)gridView didChangePagePartial:(NSInteger)page;

/**
 Called when the loaderView is being added to be view hierarchy. Use this to init animations...
 
 @param gridView The calling SMGridView
 @param loaderView The view to be used as a loader. Typically a UIActivityIndicatorView but could be anything
 */
- (void)smGridView:(SMGridView *)gridView didShowLoaderView:(UIView *)loaderView;

/**
 Called when loaderView is hidden. This gives you the change to stop animations...
 
 @param gridView The calling SMGridView
 @param loaderView The view to be used as a loader. Typically a UIActivityIndicatorView but could be anything
 */
- (void)smGridView:(SMGridView *)gridView didHideLoaderView:(UIView *)loaderView;

/**
 Called when a view starts being dragged
 
 @param gridView The calling SMGridView
 @param view The view being Dragged
 @param index The index inside its section of this view
 */
- (void)smGridView:(SMGridView *)gridView startDraggingView:(UIView *)view atIndex:(int)index;

/**
 Called when a view stops being dragged
 
 @param gridView The calling SMGridView
 @param view The view being Dragged
 @param index The index inside its section of this view
 */
- (void)smGridView:(SMGridView *)gridView stopDraggingView:(UIView *)view atIndex:(int)index;

@end


/**
 This open-source class allows you to have a custom grid that will use methods similar to UITableView (and UITableViewDataSource and UITableViewDelegate) and that supports a lot of extra functionality like:
 
 * Choose between horizontal or vertical scroll.
 * Support for any view, not just a fixed view like UITableViewCell.
 * Support for sections.
 * Support for inserting or deleting items with an animation.
 * Support to sort items using drag & drop.
 * Veeeery fast, supporting reusing views.
 * It is a UIScrollView, so you can access all its methods and set its UIScrollViewDelegate.
 * Supports pagination.
 * You can use this class even if you don't plan to scroll, just to layout items in a grid or line (single row grid).
 * Ability to display a loader at the end of the grid
 */
@interface SMGridView : UIScrollView<UIScrollViewDelegate> {
    NSMutableArray *_reusableViews;
    NSMutableArray *_items;
    NSMutableArray *_headerItems;
    NSMutableArray *_visibleItems;
    NSMutableArray *_bucketItems;
    id<SMGridViewDataSource> _dataSource;
    id<SMGridViewDelegate> _gridDelegate;
    NSInteger _currentPage;
    int _numberOfPages;
    UIView *_loaderView;
    UIView *_emptyView;
    BOOL _reloadingData;
    CGPoint _draggingPoint;
    UIControl *_draggingView;
    int _draggingItemsIndex;
    int _draggingOrigItemsIndex;
    int _draggingSection;
    NSUInteger _currentOffsetPage;
    BOOL _addingOrRemoving;
}

/**
 The SMGridViewDataSource
 */
@property (nonatomic, assign) id<SMGridViewDataSource> dataSource;

/**
 The SMGridViewDelegate
 */
@property (nonatomic, assign) id<SMGridViewDelegate> gridDelegate;

/**
 You can use this property to set the numberOfRows if all your sections have the same number. Otherwise use [SMGridViewDataSource smGridView:numberOfRowsInSection:]
 */
@property (nonatomic, assign) NSInteger numberOfRows;

/**
 This is the space between every view in the grid
 */
@property (nonatomic, assign) CGFloat padding;

/**
 In logical pixels, how much more of the size of the grid is being preloaded.
 */
@property (nonatomic, assign) CGFloat deltaLoad;

/**
 In logical pixels, use this property to make possible to preload the loaderView before it appears in the screen
 */
@property (nonatomic, assign) CGFloat deltaLoaderView;

/**
 How many extra pages to you want to preload if paging is enabled
 */
@property (nonatomic, assign) NSInteger pagesToPreload;

/**
 Set this to `YES` to have vertical scrolling
 */
@property (nonatomic, assign) BOOL vertical;

/**
 Set this property to `YES` when paging is enabled to change the order of the items
 */
@property (nonatomic, assign) BOOL pagingInverseOrder;

/**
 If pagingEnabled is `YES`, returns the current Page in the grid
 */
@property (nonatomic, assign) NSInteger currentPage;

/**
 Use this property to have a custom loaderView at the end of the grid
 Use in combination with [SMGridViewDataSource smGridViewShowLoader:]
 */
@property (nonatomic, retain) UIView *loaderView;

/**
 This view will be displayed when dataSource has no items
 */
@property (nonatomic, retain) UIView *emptyView;

/**
 If pagingEnabled is `YES`, return the total number of pages in the grid
 */
@property (nonatomic, readonly) NSInteger numberOfPages;

/**
 Use this property to have a custom loaderView at the end of the grid
 Use in combination with [SMGridViewDataSource smGridView:shouldMoveItemFrom:to:]
 */
@property (nonatomic, assign) BOOL enableSort;

/**
 In logical pixels, how far a dragged view needs to be from another view to be able to swap its position.
 */
@property (nonatomic, assign) float dragMinDistance;

/**
 This can be used to change the draggingPoint when sorting is enabled
 This is useful if you change the size of the view you are sorting.
 */
@property (nonatomic, assign) CGPoint draggingPoint;

/**
 Returns wether or not the grid is sorting or animating (adding/removing)
 */
@property (nonatomic, readonly) BOOL busy;

/**
 Decides wether headers should be sticky or not
 */
@property (nonatomic, assign) BOOL stickyHeaders;

/**
 Returns the section being shown right now
 */
@property (nonatomic, readonly) NSInteger currentSection;

/**
 Wether a grid has or not items
 */
@property (nonatomic, readonly) BOOL hasItems;

/**
 Determines time to wait after the user stops moving a view before the sort animation starts (To be deprecated)
 */
@property (nonatomic, assign) NSTimeInterval sortWaitBeforeAnimate;

/**
 Call this method once your dataSource is ready to create the views inside the grid
 */
- (void)reloadData;

/**
 Like method reloadData but only for a specific section
 
 @param section Index of section to reload
 */
- (void)reloadSection:(NSInteger)section;

/**
 Calls method reloadData and positions itself in the given page
 
 @param page Number of page to reload
 */
- (void)reloadDataWithPage:(NSInteger)page;

/**
 Like method reloadSectionOnlyNew: with section being the last section.
 */
- (void)reloadDataOnlyNew;

/**
 Use this method when you know the dataSource only added new items (and didn't change the ones before) to the given section.
 
 @param section The index of the section to reload
 */
- (void)reloadSectionOnlyNew:(NSInteger)section;

/**
 Call this method to get a reusable view
 
 @return An already used view or nils
 */
- (UIView *)dequeReusableView;

/**
 Call this method to get a reusable view of a specific class
 
 @param clazz The class you want the returning object to be
 @return A view of the provided class or nil if not available
 */
- (UIView *)dequeReusableViewOfClass:(Class)clazz;

/**
 Call this method to remove the reusable views
 */
- (void)clearReusableViews;

/**
 Like method addItemAtIndexPath:scroll: with scroll to `YES`
 
 @param indexPath IndexPath of item to add
 */
- (void)addItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 You should call this method once the dataSource has already addded the item
 
 @param indexPath The indexPath where the new item is in the property dataSource
 @param scroll indicates wether the grid should scroll to show the animation or not
 */
- (void)addItemAtIndexPath:(NSIndexPath *)indexPath scroll:(BOOL)scroll;

/**
 Like method removeItemAtIndexPath:scroll: with scroll to `YES`
 
 @param indexPath indexPath of item to remove
 */
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 You should call this method before the property dataSource has removed the item. Once the item is removed (after the animation), the dataSource will receive a call to smGridView:performRemoveIndexPath: to finally remove the item
 
 @param indexPath The indexPath in the property dataSource you want to remove
 @param scroll indicates wether the grid should scroll to show the animation or not
 */
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath scroll:(BOOL)scroll;

/**
 @param view The view whose indexPath you are interested
 @return The NSIndexPath associated with a view. nil if the view is not being shown
 */
- (NSIndexPath *)indexPathForView:(UIView *)view;

/**
 @param indexPath The target indexPath
 @return The view associated with an indexPath if it is being shown. Return nil if it is not being shown.
 */
- (UIView *)viewForIndexPath:(NSIndexPath *)indexPath;

/**
 Sets the contentOffset to 0
 
 @param animated Wether or not to animate the scroll
 */
- (void)resetScroll:(BOOL)animated;

/**
 Change the current page if paging is enabled
 
 @param page The new page number
 @param animated Wether or not to animate when moving to that page
 */
- (void)setCurrentPage:(NSInteger)page animated:(BOOL)animated;

/**
 Same as method currentViews: with includeHeaders to `NO`
 */
- (NSArray *)currentViews;

/**
 @return All visible views
 @param includeHeaders Set to `YES` to also get header views back
 */
- (NSArray *)currentViews:(BOOL)includeHeaders;

/**
 @return eturns headerView for section if the view is being shown. Headers are not supported if `pagingEnabled`is `YES`
 @param section Section number
 */
- (UIView *)headerViewForSection:(NSInteger)section;

/**
 @return The contentOffset for a page if pagingEnabled is `YES`
 @param page Page number
 */
- (CGPoint)contentOffsetForPage:(NSInteger)page;

/**
 Use this method to simulate a touchDown event to start dragging
 @param controlView The view touched
 @param point Location inside controlView
 */
- (void)touchDown:(UIControl *)controlView withLocationInView:(CGPoint)point;

@end

