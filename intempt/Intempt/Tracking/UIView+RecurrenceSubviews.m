//
//  UIView+RecurrenceSubviews.m
//  Intempt
//
//  Created by Appsbee LLC on 20/09/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "UIView+RecurrenceSubviews.h"

@implementation UIView (RecurrenceSubviews)

- (NSArray<UIView *> *)recurrenceAllSubviews {
    NSMutableArray <UIView *> *all = @[].mutableCopy;
   void (^getSubViewsBlock)(UIView *current) = ^(UIView *current){
        [all addObject:current];
        for (UIView *sub in current.subviews) {
            [all addObjectsFromArray:[sub recurrenceAllSubviews]];
        }
    };
    getSubViewsBlock(self);
    return [NSArray arrayWithArray:all];
}

@end
