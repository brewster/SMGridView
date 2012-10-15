//
//  UIColor(Random).m
//  SMGridView
//
//  Created by Miguel Cohnen on 10/3/12.
//  Copyright (c) 2012 Brewster. All rights reserved.
//

#import "UIColor+Random.h"

@implementation UIColor(Random)

+ (UIColor *)randomColor {
	CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
	CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
	return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
