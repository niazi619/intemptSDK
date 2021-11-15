//
//  IntemptUIViewDerivativesSerializer.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import UIKit;

#import <objc/runtime.h>

typedef enum nthNotationTypes {
    NTH_CHILD,
    NTH_OF_TYPE
} ITNthNotation;

typedef enum viewPathTypeType {
    CSS_PATH
} ITViewPathType;

@interface IntemptUIViewDerivativesSerializer : NSObject

+ (NSDictionary*)serializeUIViewDerivative:(id)view;

@end
