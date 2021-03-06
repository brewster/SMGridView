//
//  MasterViewController.m
//  navTest
//
//  Created by Miguel Cohnen on 9/26/12.
//  Copyright (c) 2012 Miguel Cohnen. All rights reserved.
//

#import "SMGridViewTestViewController.h"
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "UIColor+Random.h"

#define kGridMargin 10
#define kHeaderSize 50

@interface SMGridViewTestViewController () {
    IASKAppSettingsViewController *_appSettingsViewController;
    SMGridView *_gridView;
    UISwitch *_sortSwitch;
}

@property (nonatomic, retain) NSMutableArray *sections;

@end

@implementation SMGridViewTestViewController

@synthesize sections = _sections;

- (id)init {
    self = [super init];
    if (self) {
        // This just sets the default values for our Settings
        [[NSUserDefaults standardUserDefaults] registerDefaults:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInt:4], @"num_sections",
          [NSNumber numberWithBool:NO], @"vertical",
          [NSNumber numberWithInt:200], @"num_items",
          [NSNumber numberWithInt:50], @"item_size",
          [NSNumber numberWithDouble:100], @"sort_time",
          nil]];
    }
    return self;
}
							
- (void)dealloc {
    [_appSettingsViewController release];
    [_gridView release];
    [_sections release];
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    [self createGrid];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self reloadGrid];
    
    [self setupButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadGrid];
}

- (void)viewWillLayoutSubviews {
    [_gridView reloadData];
}

- (UIView *)createEmptyView {
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 300)] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:36];
    label.text = @"I'm empty :(";
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (void)createGrid {
    // Create the grid based on the current's vc view and a margin
    _gridView = [[SMGridView alloc] initWithFrame:CGRectMake(kGridMargin, kGridMargin, self.view.frame.size.width - 2*kGridMargin, self.view.frame.size.height - 2*kGridMargin)];
    _gridView.backgroundColor = [UIColor whiteColor];
    // Make it resizable
    _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    // Empty view
    _gridView.emptyView = [self createEmptyView];
    // We set ourselfs (vc) as both dataSource and delegate
    _gridView.gridDelegate = self;
    _gridView.dataSource = self;
    [self.view addSubview:_gridView];
}


/**
 This method will reload the grid reading all the properties in the settings
 */
- (void)reloadGrid {
    // Always disable sort
    _gridView.enableSort = NO;
    _sortSwitch.on = NO;
    
    _gridView.vertical = [[NSUserDefaults standardUserDefaults] boolForKey:@"vertical"];
    _gridView.pagingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"pagination_enabled"];
    _gridView.pagingInverseOrder = [[NSUserDefaults standardUserDefaults] boolForKey:@"pagination_reverse"];
    _gridView.sortWaitBeforeAnimate = [[NSUserDefaults standardUserDefaults] doubleForKey:@"sort_time"]/1000;
    _gridView.stickyHeaders = [[NSUserDefaults standardUserDefaults] boolForKey:@"headers_sticky"];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"loader_enabled"]) {
        // Create the activity indicator as a loder view
        UIActivityIndicatorView *av = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
        av.color = [UIColor darkGrayColor];
        [av startAnimating];
        _gridView.loaderView = av;
    } else {
        _gridView.loaderView = nil;
    }
    // Update the items (dataSource)
    [self createItems:[[NSUserDefaults standardUserDefaults] integerForKey:@"num_items"]];
    
    // Call reloadData to make sure all the changes are applied
    [_gridView reloadData];
}

// Headers are not supported in paging mode right now
- (BOOL)headersEnabled {
    return !_gridView.pagingEnabled && [[NSUserDefaults standardUserDefaults] boolForKey:@"headers_enabled"];
}

// This section is to create the mock color boxes for our grid
#pragma mark - Items

- (float)varSize {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"squares"]) {
        return self.itemSize;
    } else {
        int varSize[] = {50, 70, 90, 110};
        return varSize[arc4random()%4];
    }
}

// Create random items
- (NSDictionary *)createItem:(NSString *)label {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[UIColor randomColor] forKey:@"color"];
    if (_gridView.pagingEnabled) {
        [dict setObject:[NSNumber numberWithInt:self.itemSize] forKey:@"height"];
        [dict setObject:[NSNumber numberWithInt:self.itemSize] forKey:@"width"];
    }else {
        if (_gridView.vertical) {
            [dict setObject:[NSNumber numberWithInt:self.varSize] forKey:@"height"];
            [dict setObject:[NSNumber numberWithInt:self.itemSize] forKey:@"width"];
        }else {
            [dict setObject:[NSNumber numberWithInt:self.varSize] forKey:@"width"];
            [dict setObject:[NSNumber numberWithInt:self.itemSize] forKey:@"height"];
        }
    }
    [dict setObject:label forKey:@"label"];
    return dict;
}

- (void)createItems:(int)numItems {
    NSMutableArray *tmp = [NSMutableArray array];
    for (int s = 0; s < [self numberOfSectionsInSMGridView:_gridView]; s++) {
        NSMutableArray *tmpItems = [NSMutableArray array];
        for (int i=0; i<numItems; i++) {
            [tmpItems addObject:[self createItem:[NSString stringWithFormat:@" %i ", i]]];
        }
        [tmp addObject:tmpItems];
    }
    
    self.sections = tmp;
}

- (NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath {
    return [[_sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (int)numSections {
    if (_gridView.pagingEnabled) {
        return 1;
    } else {
        return [[[NSUserDefaults standardUserDefaults] objectForKey:@"num_sections"] intValue];
    }
}

- (int)itemSize {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"item_size"];
}

#pragma mark - SMGridViewDataSource

- (int)numberOfSectionsInSMGridView:(SMGridView *)gridView {
    return [self numSections];
}

- (int)smGridView:(SMGridView *)gridView numberOfRowsInSection:(NSInteger)section {
    if (gridView.vertical) {
        return floor(gridView.frame.size.width/(self.itemSize + gridView.padding));
    } else {
        return floor(gridView.frame.size.height/(self.itemSize + gridView.padding));
    }
}

- (int)smGridView:(SMGridView *)gridView numberOfItemsInSection:(NSInteger)section {
    return [[_sections objectAtIndex:section] count];
}

- (UIView *)smGridView:(SMGridView *)gridView viewForIndexPath:(NSIndexPath *)indexPath {
    UIButton *view = (UIButton *)[gridView dequeReusableViewOfClass:[UIButton class]];
    if (!view) {
        view = [UIButton buttonWithType:UIButtonTypeCustom];
        view.userInteractionEnabled = YES;
        view.titleLabel.adjustsFontSizeToFitWidth = YES;
        //        [view addTarget:self action:@selector(itemPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    NSDictionary *item = [self itemAtIndexPath:indexPath];
    view.backgroundColor = [item objectForKey:@"color"];
    CGRect rect = view.frame;
    rect.size.width = [[item objectForKey:@"width"] intValue];
    rect.size.height = [[item objectForKey:@"height"] intValue];
    view.frame = rect;
    [view setTitle:[item objectForKey:@"label"] forState:UIControlStateNormal];
    return view;
}

- (CGSize)smGridView:(SMGridView *)gridView sizeForIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [self itemAtIndexPath:indexPath];
    return CGSizeMake([[dict objectForKey:@"width"] intValue],
                      [[dict objectForKey:@"height"] intValue]);
}

- (UIView *)smGridView:(SMGridView *)gridView viewForHeaderInSection:(NSInteger)section {
    if (!self.headersEnabled || [self smGridView:gridView numberOfItemsInSection:section] == 0) {
        return nil;
    }
    static NSArray *colors;
    if (!colors) {
        colors = [[NSArray alloc] initWithObjects:[UIColor grayColor], [UIColor blackColor], nil];
    }
    UIView *header = [[[UIView alloc] init] autorelease];
    
    CGSize headerSize = [self smGridView:gridView sizeForHeaderInSection:section];
    header.frame = CGRectMake(0, 0, headerSize.width, headerSize.height);
    header.backgroundColor = [colors objectAtIndex:section%colors.count];
    
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = CGRectMake(0, (headerSize.height - kHeaderSize)/2, header.frame.size.width, kHeaderSize);
    label.text = [NSString stringWithFormat:@"%d", section];
    label.textColor = [UIColor whiteColor];
    [header addSubview:label];
    return header;
}

- (CGSize)smGridView:(SMGridView *)gridView sizeForHeaderInSection:(NSInteger)section {
    if (!self.headersEnabled || [self smGridView:gridView numberOfItemsInSection:section] == 0) {
        return CGSizeZero;
    }
    if (gridView.vertical) {
        return CGSizeMake(gridView.frame.size.width, kHeaderSize);
    } else {
        return CGSizeMake(kHeaderSize, gridView.frame.size.height);
    }
}

- (void)smGridView:(SMGridView *)gridView performRemoveIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *array = [_sections objectAtIndex:indexPath.section];
    [array removeObjectAtIndex:indexPath.row];
}

- (void)smGridView:(SMGridView *)gridView shouldMoveItemFrom:(NSIndexPath *)from to:(NSIndexPath *)to {
    NSMutableArray *tmpItems = [_sections objectAtIndex:from.section];
    id obj = [[tmpItems objectAtIndex:from.row] retain];
    [tmpItems removeObjectAtIndex:from.row];
    [tmpItems insertObject:obj atIndex:to.row];
    [obj release];
}

- (void)smGridView:(SMGridView *)gridView startDraggingView:(UIView *)view atIndex:(int)to {
    float scale = 1.2;
    CGSize size = view.frame.size;
    gridView.draggingPoint = CGPointMake(
                                         gridView.draggingPoint.x + (size.width*scale - size.width)/2,
                                         gridView.draggingPoint.y + (size.height*scale - size.height)/2
                                         );
    [UIView animateWithDuration:0.3 animations:^{
        view.transform = CGAffineTransformMakeScale(scale, scale);
        view.alpha = 0.7;
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)smGridView:(SMGridView *)gridView stopDraggingView:(UIView *)view atIndex:(int)to {
    [UIView animateWithDuration:.3 animations:^{
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        view.alpha = 1.0;
    }];
}

- (BOOL)smGridViewShowLoader:(SMGridView *)gridView {
    return  YES;
}

- (BOOL)smGridViewSameSize:(SMGridView *)gridView {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"squares"];
}


#pragma mark - Settings

- (void)setupButtons {
    UIBarButtonItem *settingsButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(settingsAction:)] autorelease];
    self.navigationItem.rightBarButtonItem = settingsButton;
    
    _sortSwitch = [[[UISwitch alloc] init] autorelease];
    [_sortSwitch addTarget:self action:@selector(sortChanged:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *sortButton = [[[UIBarButtonItem alloc] initWithCustomView:_sortSwitch] autorelease];
    UILabel *sortLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 30)] autorelease];
    sortLabel.textAlignment = NSTextAlignmentCenter;
    sortLabel.backgroundColor = [UIColor clearColor];
    sortLabel.textColor = [UIColor whiteColor];
    sortLabel.font = [UIFont boldSystemFontOfSize:18];
    sortLabel.text = @"sort";
    UIBarButtonItem *sortLabelButton = [[[UIBarButtonItem alloc] initWithCustomView:sortLabel] autorelease];
    
    // Add/Remove
    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)] autorelease];
    UIBarButtonItem *removeButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeAction:)] autorelease];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:sortLabelButton, sortButton, addButton, removeButton, nil];
}

- (void)addAction:(id)sender {
    int section = arc4random()%_sections.count;
    int index = arc4random()%([[_sections objectAtIndex:section] count] +1);
    [[_sections objectAtIndex:section] insertObject:[self createItem:@" New"] atIndex:index];
    [_gridView addItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section]];
}

- (void)removeAction:(id)sender {
    int section = arc4random()%_sections.count;
    int index = arc4random()%([[_sections objectAtIndex:section] count]);
    [_gridView removeItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section]];
}

- (void)sortChanged:(UISwitch *)aSwitch {
    _gridView.enableSort = aSwitch.on;
}

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!_appSettingsViewController) {
		_appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        _appSettingsViewController.showDoneButton = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
        NSMutableSet *hiddenKeys = [NSMutableSet set];
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"headers_enabled"]) {
            [hiddenKeys addObject:@"headers_sticky"];
        }
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"pagination_enabled"]) {
            [hiddenKeys addObject:@"pagination_reverse"];
        }
        
        _appSettingsViewController.hiddenKeys = hiddenKeys;
	}
	return _appSettingsViewController;
}

- (void)settingsAction:(UIButton *)button {
    [self.navigationController pushViewController:self.appSettingsViewController animated:YES];
}

- (void)settingDidChange:(NSNotification *)notification {
    NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:_appSettingsViewController.hiddenKeys];
    if ([notification.object isEqual:@"headers_enabled"]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"headers_enabled"]) {
            [hiddenKeys addObject:@"headers_sticky"];
        } else {
            [hiddenKeys removeObject:@"headers_sticky"];
        }
    }
    if ([notification.object isEqual:@"pagination_enabled"]) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"pagination_enabled"]) {
            [hiddenKeys addObject:@"pagination_reverse"];
        } else {
            [hiddenKeys removeObject:@"pagination_reverse"];
        }
    }
    [_appSettingsViewController setHiddenKeys:hiddenKeys animated:YES];
}

@end
