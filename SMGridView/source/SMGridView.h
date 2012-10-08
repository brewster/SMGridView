//
//  SMGridView.h
//  SMGridView
//
//  Created by Miguel Cohnen on 28/10/11.
//  Copyright (c) 2012 Brewster. All rights reserved.
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
 @param fromIndexPath The original indexPath
 @param toIndexPath The new indexPath
 */
- (void)smGridView:(SMGridView *)gridView shouldMoveItemFrom:(NSIndexPath *)fromIndexPath to:(NSIndexPath *)indexPath;

/**
 This method will be called when a remove animation is finished. `SMGridViewDataSource` should remove the item at indexPath position in the implementation of this method
 @param gridView The calling SMGridView
 @param section The indexPath to delete
 */
- (void)smGridView:(SMGridView *)gridView performRemoveIndexPath:(NSIndexPath *)indexPath;

/**
 Use this method to decide wether to show a loader or not. Typically you make your `SMGridViewDataSource` manage this method and returning `YES`or `NO` if it is loading more content.
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
 
 @return The number of sections in the grid
 */
- (NSInteger)numberOfSectionsInSMGridView:(SMGridView *)gridView;

/**
 Implement this method if you want to have header views for your section
 
 @return The size of the header in the given section. Return CGSizeZero if no header
 */
- (CGSize)smGridView:(SMGridView *)gridView sizeForHeaderInSection:(NSInteger)section;

/**
 Implement this method if you want to have header views for your section
 
 @return The header view for a given section. Return nil if no header.
 */
- (UIView *)smGridView:(SMGridView *)gridView viewForHeaderInSection:(NSInteger)section;

/**
 Implement this method in combination with property [SMGridView enableSort] to be able to move items
 
 @return `YES` if an item at the given indexPath can be moved.
 */
- (BOOL)smGridView:(SMGridView *)gridView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;
@end


/**
 This is the Delegate
 */
@protocol SMGridViewDelegate <UIScrollViewDelegate>
@optional

/*!
 @brief Called when the adding animation finishes
 */
- (void)smGridView:(SMGridView *)gridView didFinishAddingIndexPath:(NSIndexPath *)indexPath;

/*!
 @brief Called when the remove animation finishes
 */
- (void)smGridView:(SMGridView *)gridView didFinishRemovingIndexPath:(NSIndexPath *)indexPath;

/*!
 @brief Called when a page changes, and only after the scroll finishes
 */
- (void)smGridView:(SMGridView *)gridView didChangePage:(NSInteger)page;

/*!
 @brief Called when a page changes. This means that a new page is more visible than the previous
 */
- (void)smGridView:(SMGridView *)gridView didChangePagePartial:(NSInteger)page;

/*!
 @brief Called when loader view is shown. This gives you the change to start animatinos...
 */
- (void)smGridView:(SMGridView *)gridView didShowLoaderView:(UIView *)loaderView;

/*!
 @brief Called when loader view is hide. This gives you the change to stop animatinos...
 */
- (void)smGridView:(SMGridView *)gridView didHideLoaderView:(UIView *)loaderView;

/*!
 @brief Called when a view starts being dragged
 */
- (void)smGridView:(SMGridView *)gridView startDraggingView:(UIView *)view atIndex:(int)to;

/*!
 @brief Called when a view stops being dragged
 */
- (void)smGridView:(SMGridView *)gridView stopDraggingView:(UIView *)view atIndex:(int)to;

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

/*!
 @property
 */
@property (nonatomic, assign) id<SMGridViewDataSource> dataSource;

/*!
 @property
 */
@property (nonatomic, assign) id<SMGridViewDelegate> gridDelegate;
@property (nonatomic, assign) NSInteger numberOfRows;

/*!
 @property
 @brief This is the space between every view in the grid
 */
@property (nonatomic, assign) CGFloat padding;

/*!
 @property
 @brief In logical pixels, how much more of the size of the grid is being preloaded.
 */
@property (nonatomic, assign) CGFloat deltaLoad;

/*!
 @property
 @brief In logical pixels, use this property to make possible to preload the loaderView before it appears in the screen
 */
@property (nonatomic, assign) CGFloat deltaLoaderView;

/*!
 @property
 @brief How many extra pages to you want to preload if paging is enabled
 */
@property (nonatomic, assign) NSInteger pagesToPreload;

/*!
 @property
 @brief Set this to yes to have vertical scrolling
 */
@property (nonatomic, assign) BOOL vertical;

/*!
 @property
 @brief Set this property to yes when paging is enabled to change the order of the items
 */
@property (nonatomic, assign) BOOL pagingInverseOrder;

/*!
 @property
 */
@property (nonatomic, assign) NSInteger currentPage;

/*!
 @property
 @brief Use this property to have a custom loaderView at the end of the grid
 @discussion Use in combination with dataSource method smGridViewShowLoader:
 */
@property (nonatomic, retain) UIView *loaderView;

/*!
 @property
 @brief This view will be displayed when dataSource has no items
 */
@property (nonatomic, retain) UIView *emptyView;

/*!
 @property
 */
@property (nonatomic, readonly) NSInteger numberOfPages;

/*!
 @property
 @brief Use this property to have a custom loaderView at the end of the grid
 @discussion Use in combination with dataSource method smGridView:shouldMoveItemFrom:to:
 */
@property (nonatomic, assign) BOOL enableSort;

/*!
 @property
 @brief In logical pixels, how far a dragged view needs to be from another view to be able to swap its position.
 */
@property (nonatomic, assign) float dragMinDistance;

/*!
 @property
 @brief This can be used to change the draggingPoint when sorting is enabled
 @discussion This is useful if you change the size of the view you are sorting.
 */
@property (nonatomic, assign) CGPoint draggingPoint;

/*!
 @property
 @brief If the grid is sorting or animating (adding/removing)
 */
@property (nonatomic, readonly) BOOL busy;

/*!
 @property
 @brief Decides wether headers should be sticky or not
 */
@property (nonatomic, assign) BOOL stickyHeaders;

/*!
 @property
 @brief Returns the section being shown right now
 */
@property (nonatomic, readonly) NSInteger currentSection;

/*!
 @property
 @brief Wether a grid has or not items
 */
@property (nonatomic, readonly) BOOL hasItems;

/*!
 @property
 @brief this is short
 @discussion This is a bigger text
 */
@property (nonatomic, assign) NSTimeInterval sortWaitBeforeAnimate;

/*!
 @brief Call this method once your dataSource is ready to create the views inside the grid
 */
- (void)reloadData;

/*!
 @brief Like @link reloadData @/link but only for a specific section
 */
- (void)reloadSection:(NSInteger)section;

/*!
 @brief Calls reloadData and positions itself in the given page
 */
- (void)reloadDataWithPage:(NSInteger)page;

/*!
 @brief reloadSectionOnlyNew: with section being the last section.
 */
- (void)reloadDataOnlyNew;

/*!
 @brief Use this method when you know the dataSource only added new items (and didn't change the ones before) to the given section.
 */
- (void)reloadSectionOnlyNew:(NSInteger)section;

/*!
 @brief Call this method to get a reusable view
 */
- (UIView *)dequeReusableView;

/*!
 @brief Call this method to get a reusable view of a specific class
 */
- (UIView *)dequeReusableViewOfClass:(Class)class;

/*!
 @brief Call this method to remove the reusable views
 */
- (void)clearReusableViews;

/*!
 @brief Like @link addItemAtIndexPath:scroll: @/link with scroll == YES
 */
- (void)addItemAtIndexPath:(NSIndexPath *)indexPath;

/*!
 @method addItemAtIndexPath:scroll:
 @brief You should call this method once the dataSource has already addded the item.
 @param scroll
    indicates wether the grid should scroll to show the animation or not.
 */
- (void)addItemAtIndexPath:(NSIndexPath *)indexPath scroll:(BOOL)scroll;

/*!
 @brief Like @link removeItemAtIndexPath:scroll: @/link with scroll == YES
 */
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath;

/*!
 @brief You should call this method before the dataSource has removed the item. Once the item is removed (after the animation), the dataSource will receive a call to smGridView:performRemoveIndexPath: to finally remove the item.
 @param scroll
 indicates wether the grid should scroll to show the animation or not.
 */
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath scroll:(BOOL)scroll;

/*!
 @brief Returns the indexpath associated with a view.
 */
- (NSIndexPath *)indexPathForView:(UIView *)view;

/*!
 @brief Returns the view associated with an indexPath if it is being shown. Return nil if it is not being shown.
 */
- (UIView *)viewForIndexPath:(NSIndexPath *)indexPath;

/*!
 @brief Sets the contentOffset to 0
 */
- (void)resetScroll:(BOOL)animated;

/*!
 @brief change the current page if paging is enabled
 @param page
    The new page number
 @param animated
    Wether to animate when moving to that page
 */
- (void)setCurrentPage:(NSInteger)page animated:(BOOL)animated;

/*!
 @brief Same as currentViews with includeHeaders = NO
 */
- (NSArray *)currentViews;

/*!
 @brief return all visible views
 @param includeHeaders
    Set to YES to also get header views back
 */
- (NSArray *)currentViews:(BOOL)includeHeaders;

/*!
 @brief Returns headerView for section if the view is being shown. Headers are not supported if `pagingEnabled`is activated
 @param section
    Section number
 */
- (UIView *)headerViewForSection:(NSInteger)section;

/*!
 @brief Returns the contentOffset for a page if paging is enabled
 @param page
    Page number
 */
- (CGPoint)contentOffsetForPage:(NSInteger)page;

/*!
 @brief Use this method to simulate a touchDown event to start dragging
 @param controlView
    The view touched
 @param point
    Location inside controlView
 */
- (void)touchDown:(UIControl *)controlView withLocationInView:(CGPoint)point;

@end

