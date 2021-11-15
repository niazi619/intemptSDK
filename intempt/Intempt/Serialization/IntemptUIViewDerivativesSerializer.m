//
//  IntemptUIViewDerivativesSerializer.m
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

#import "IntemptUIViewDerivativesSerializer.h"

@implementation IntemptUIViewDerivativesSerializer

static NSDictionary* trackedTypesAndProperties;
static NSDictionary* nonUIViewBasedItems;
static NSArray* excludedProperties;
static NSArray* excludedTypes;
static NSArray* excludedTypesClasses;
static NSArray* excludedPropertiesForSecure;
static NSArray* ignoreCustomPropertiesForSubtypesOf;
static int maxDepth = 2;
static bool trackCustomProperties = YES;
static int notaion = NTH_CHILD;
//static int pathType = CSS_PATH;

+ (void)initialize {
    if (self == [IntemptUIViewDerivativesSerializer class]) {
        /*
         
         Here we describe properties that we wish to track for each specific UIView derivative
         and UIView itself.
         
         excludedTypes list contains types of properties, that would not be serialized, thus properties
         of these types are ignored. The check is "contains" for type string, so there is no need to
         specify the type name exactly
         
         excludedTypesClasses are the same types, converted to classes to check for ancestors and ignore
         them too
         
         ignoreCustomPropertiesForSubtypesOf for direct ancestors of these types custom properties will
         not be tracked. A good example can be a subtype of UIView directly - there, most likely, will
         be too many properties to track regardless. trackCustomProperties flag for these types is
         overridden to NO.
         Currently, this array is empty, but is to get filled up later on
         
         excludedProperties list contains the properties that will be explicitly ignored when an entity
         comes to serialization, client is guaranteed to not see.
         
         excludedPropertiesForSecure lists property names, that contain data to not be tracked
         for SECURE views
         
         trackedTypesAndProperties is a MONSTROUS dictionary, containing info for each type we
         might receive as an entity and *, containing properties, tracked for all the classes.
         Some classes have empty dictionaries here, which is completely intentional - we don't
         want anything but the class name and "common" properties from * to be tracked for them
         
         Some classes have custom serialization aded to them (for instance, UIPickerView).
         Check out the implementation of serializeUIViewDerivative:withDepth: method for details
         
         */
        
        excludedTypes = @[@"NSArray", @"NSMutableArray", @"NSPointerArray", @"NSDictionary",
                          @"NSMutableDictionary", @"NSMapTable", @"NSSet", @"NSMutableSet", @"NSCountedSet", @"NSHashTable", @"UIImage"];
        
        excludedProperties = @[@"superclass", @"debugDescription", @"delegate", @"description", @"hash"];
        
        excludedPropertiesForSecure = @[@"text", @"abText", @"_text"];
        
        ignoreCustomPropertiesForSubtypesOf = @[];
        
        trackedTypesAndProperties = @{
                                      // @"nil" type will get into class parsing for sure
                                      @"*": @{@"tag": @"NSInteger", @"hidden": @"BOOL", @"alpha": @"CGFloat", @"accessibilityLabel": @"NSString", @"accessibilityIdentifier": @"NSString"},
                                      
                                      @"UISearchBar": @{@"text": @"NSString", @"placeholder": @"NSString", @"prompt": @"NSString",},
                                      
                                      @"UIActivity": @{@"activityTitle": @"NSString", @"activityType": @"NSString"},
                                      
                                      @"UIButton": @{@"currentTitle": @"NSString", @"buttonType": @"UIButtonType"},
                                      
                                      @"UINavigationButton": @{@"title": @"NSString"},
                                      
                                      @"UILabel": @{@"text": @"NSString"},
                                      
                                      @"UIPageControl": @{@"currentPage": @"NSInteger"},
                                      
                                      @"UIPickerView": @{
                                              //Has custom serialization
                                      },
                                      
                                      @"UIDatePicker": @{@"date": @"NSDate",@"timeZone": @"NSTimeZone"},
                                      
                                      @"UISegmentedControl": @{@"selectedSegmentIndex": @"NSInteger",@"selectedSegmentTitle": @"NSString"
                                              //Also has some custom serialization
                                              },
                                      
                                      @"UISlider": @{@"value": @"float",},
                                      
                                      @"UIStepper": @{@"value": @"double",},
                                      
                                      @"UISwitch": @{@"on": @"BOOL"},
                                      
                                      @"UITextField": @{@"text": @"NSString", @"placeholder": @"NSString"},
                                      
                                      @"UITextView": @{@"text": @"NSString"}
                                      };
        nonUIViewBasedItems = @{
                                // non-UIView based items
                                // for such items we have to define, where does the
                                // view in them live to get the view and parse it
                                @"UIBarButtonItem": @"view"
                                };
        // convert excluded types to classes for checks
        NSMutableArray *excludedTypesClassesTmp = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < [excludedTypes count]; i++) {
            [excludedTypesClassesTmp addObject:NSClassFromString(excludedTypes[i])];
        }
        excludedTypesClasses = excludedTypesClassesTmp;
    }
}

+ (id)serializePropertyValue:(id)value ofType:(NSString*)type withDepth:(int)depth {
    /*
     This method knows how to serialize different types.
     If some property/type should not be serialized, the method returns nil and caller must take
     that into consideration by NOT including such a value
     */
    if (!value) {
        [NSException raise:@"Invalid arguments" format:@"No value was provided to serialization function"];
    }
    UILabel *lbl = [[UILabel alloc] init];
    lbl.attributedText = [[NSAttributedString alloc] init];
    for (NSUInteger i = 0; i < [excludedTypes count]; i++) {
        if ([type containsString:excludedTypes[i]]) {
            // it is of excluded type, we DO NOT serialize anything about them yet
            return nil;
        }
    }
    
    if (type) {
        if (depth >= maxDepth) {
            // we exceeded the depth, ignore property
            //
            // this is more of a safeguard, this endpoint should not be triggered
            return nil;
        }
        
        NSDictionary* typeSubdict = [trackedTypesAndProperties objectForKey:type];
        
        if (typeSubdict) {
            // this type can be further serialized as UIView, so we will do it
            
            if (depth + 1 >= maxDepth) {
                // however, it will be too deep, so we cut short here
                return nil;
            }
            
            return [self serializeUIViewDerivative:value withDepth:depth + 1];
        } else {
            // define new parsers of types here
            if ([type isEqualToString:@"UIColor"]) {
                CGFloat r, g, b, a;
                [value getRed: &r green:&g blue:&b alpha:&a];
                return [NSString stringWithFormat:@"rgba(%d, %d, %d, %d)", (int)roundf(r), (int)roundf(g), (int)roundf(b), (int)roundf(a)];
            } else if ([type isEqualToString:@"NSTextAlignment"]) {
                NSTextAlignment valueAsAlignment = [value integerValue];
                switch (valueAsAlignment) {
                    case NSTextAlignmentLeft:
                        return @"left";
                    case NSTextAlignmentRight:
                        return @"right";
                    case NSTextAlignmentCenter:
                        return @"center";
                    case NSTextAlignmentNatural:
                        return @"natural";
                    case NSTextAlignmentJustified:
                        return @"justified";
                    default:
                        [NSException raise:@"Unknown alignment" format:@"Unknown alignment value \"%@\" encountered", value];
                }
            } else if ([type isEqualToString:@"BOOL"] || [type isEqualToString:@"Boolean"]) {
                if ([value boolValue]) {
                    return @"true";
                } else {
                    return @"false";
                }
            } else if ([type isEqualToString:@"UIFont"]) {
                UIFont* fontValue = value;
                
                NSMutableDictionary* fontDict = [[NSMutableDictionary alloc] init];
                [fontDict setObject:[fontValue fontName] forKey:@"font-family"];
                [fontDict setObject:[NSString stringWithFormat:@"%.2fpt", [fontValue pointSize]] forKey:@"font-size"];
                
                NSError* err = nil;
                NSString* fontDescription = [fontValue description];
                NSRange   searchedRange = NSMakeRange(0, [fontDescription length]);
                NSRegularExpression* fontWeightRegex = [NSRegularExpression regularExpressionWithPattern:@"font-weight\\:\\s*([^;]+?);" options:0 error:&err];
                if (err) {
                    [NSException raise:@"Error when creating a regex for font weight" format:@"Error: %@", err];
                }
                NSTextCheckingResult* fontWeightMatch = [fontWeightRegex firstMatchInString:fontDescription options:0 range: searchedRange];
                if (fontWeightMatch) {
                    [fontDict setObject:[fontDescription substringWithRange:[fontWeightMatch rangeAtIndex:1]] forKey:@"font-weight"];
                }
                
                NSRegularExpression* fontStyleRegex = [NSRegularExpression regularExpressionWithPattern:@"font-style\\:\\s*([^;]+?);" options:0 error:&err];
                if (err) {
                    [NSException raise:@"Error when creating a regex for font weight" format:@"Error: %@", err];
                }
                NSTextCheckingResult* fontStyleMatch = [fontStyleRegex firstMatchInString:[fontValue description] options:0 range: searchedRange];
                if (fontStyleMatch) {
                    [fontDict setObject:[fontDescription substringWithRange:[fontStyleMatch rangeAtIndex:1]] forKey:@"font-style"];
                }
                
                return fontDict;
            } else if ([type isEqualToString:@"UIButtonType"]) {
                UIButtonType valueAsButtonType = [value integerValue];
                switch (valueAsButtonType) {
                    case UIButtonTypeCustom:
                        return @"custom";
                        /* currently, this is the same as RoundedRect type, so it's skipped */
                        //                    case UIButtonTypeSystem:
                        //                        return @"system";
                    case UIButtonTypeDetailDisclosure:
                        return @"detail_disclosure";
                    case UIButtonTypeInfoLight:
                        return @"info_light";
                    case UIButtonTypeInfoDark:
                        return @"info_dark";
                    case UIButtonTypeContactAdd:
                        return @"contact_add";
                    case UIButtonTypeRoundedRect:
                        return @"rounded_rect";
                    default:
                        // what if, right? we return description by default here as well
                        return [value description];
                }
            }
        }
    }
    
    return [value description];
}

+ (NSString*)getUIViewType:(UIView*)view {
    Class currentClass = [view class];
    NSString* viewTypeString = NSStringFromClass(currentClass);
    
    while (![trackedTypesAndProperties objectForKey:viewTypeString] && ![viewTypeString hasPrefix:@"UI"] && ![viewTypeString isEqual: @"NSObject"]) {
        currentClass = [currentClass superclass];
        viewTypeString = NSStringFromClass(currentClass);
    }
    
    return viewTypeString;
}

+ (NSSet<NSString*>*) getPropertiesList:(UIView*)view {
    @autoreleasepool {
        Class currentClass = [view class];
        NSString* viewTypeString = NSStringFromClass(currentClass);
        NSMutableSet<NSString*>* propertiesSet = [[NSMutableSet<NSString*> alloc] init];
        NSDictionary* typeSubdict = [trackedTypesAndProperties objectForKey:viewTypeString];
        
        while (!typeSubdict &&
               ![viewTypeString hasPrefix:@"UI"] &&
               ![viewTypeString isEqual: @"NSObject"]) {
            unsigned int numberOfProperties = 0;
            objc_property_t *propertyArray = class_copyPropertyList(currentClass, &numberOfProperties);
            
            for (NSUInteger i = 0; i < numberOfProperties; i++) {
                objc_property_t property = propertyArray[i];
                const char * name = property_getName(property);
                NSString *propertyName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
                
                [propertiesSet addObject:propertyName];
            }
            
            currentClass = [currentClass superclass];
            viewTypeString = NSStringFromClass(currentClass);
            typeSubdict = [trackedTypesAndProperties objectForKey:viewTypeString];
        }
        
        for (NSString* propertyName in [typeSubdict allKeys]) {
            [propertiesSet addObject:propertyName];
        }
        
        // add common properties to the list of properties
        for (NSString* propertyName in [[trackedTypesAndProperties objectForKey:@"*"] allKeys]) {
            [propertiesSet addObject:propertyName];
        }
        
        return propertiesSet;
    }
}

+ (NSString*)getTypeForProperty:(NSString*)propertyName inObject:(id)object {
    @autoreleasepool {
        objc_property_t property = class_getProperty([object class], propertyName.UTF8String);
        
        const char * type = property_getAttributes(property);
        
        NSString * typeString = [NSString stringWithUTF8String:type];
        NSArray * attributes = [typeString componentsSeparatedByString:@","];
        NSString * typeAttribute = [attributes objectAtIndex:0];
        NSString * propertyType = [typeAttribute substringFromIndex:1];
        
        if ([typeAttribute hasPrefix:@"T@"]) {
            NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  //turns @"NSDate" into NSDate
            return typeClassName;
        } else {
            return propertyType;
        }
    }
}

+ (NSString*)getNthPostfixForView:(UIView*)view withParent:(UIView*)parent {
    uint nthOfType = -1,
    nthChild = 1,
    sameClassSiblingsCount = 1,
    currentChildrenCount = 1;
    
    for (UIView* subview in parent.subviews) {
        if ([subview isKindOfClass:[view class]]) {
            // Found a sibling of the same class here
            if (subview == view) {
                // this sibling is our view now
                nthOfType = sameClassSiblingsCount;
                nthChild = currentChildrenCount;
            }
            sameClassSiblingsCount++;
        }
        currentChildrenCount++;
    }
    
    if (sameClassSiblingsCount > 1) {
        switch (notaion) {
            case NTH_CHILD:
                return [NSString stringWithFormat:@":nth-child(%i)", nthChild];
                break;
            case NTH_OF_TYPE:
                return [NSString stringWithFormat:@":nth-of-type(%i)", nthOfType];
            default:
                break;
        }
    }
    
    return @"";
}

+ (NSString*)getPathForView:(UIView*)view {
    return [self getPathForView:view withPath:nil];
}

+ (NSString*)getPathForView:(UIView*)view withPath:(NSString*)path {
    NSMutableString* res = [NSMutableString stringWithString:NSStringFromClass([view class])];
    NSString* prependedPath = path ? [NSString stringWithFormat:@" > %@", path] : @"";
    
    UIView* parent = [view superview];
    if (parent) {
        [res appendString:[self getNthPostfixForView:view withParent:parent]];
        
        return [self getPathForView:parent withPath:[NSString stringWithFormat:@"%@%@", res, prependedPath]];
    } else {
        // we've reached window level, no more parents
        return [NSString stringWithFormat:@"%@%@", res, prependedPath];
    }
}
+ (UIViewController *)viewControllerForView:(UIView*)view {
    UIResponder *responder = view;
    while (![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return (UIViewController *)responder;
}


+ (NSDictionary*)serializeUIViewDerivative:(id)entity withDepth:(int)depth {
    // filter off secure text entries
    BOOL isSecure = NO;
    if ([entity isKindOfClass:[UITextField class]]) {
        UITextField* viewAsTextField = (UITextField*)entity;
        // it is a text field of a sort
        // check, whether it's a password field -
        // and if it is, ignore it
        
        isSecure = viewAsTextField.secureTextEntry;
    }
    
    NSMutableDictionary* serializedView = [[NSMutableDictionary alloc] init];
    
    NSString *entityClass = NSStringFromClass([entity class]);
    if (!entityClass) {
        return serializedView;
    }
    [serializedView setObject:entityClass forKey:@"class"];
    
    UIView *view = nil;
    if (![entity isKindOfClass:[UIView class]]) {
        NSString *viewLocationString = [nonUIViewBasedItems objectForKey:entityClass];
        if (viewLocationString) {
            view = [entity valueForKey:viewLocationString];
            if (view) {
                // add view class information to tracked data
                [serializedView setObject:NSStringFromClass([view class]) forKey:@"viewClass"];
            }
        }
        
        if (!view) {
            // it's not a view and not explicitly tracked, we don't track properties for these
            return serializedView;
        }
    } else {
        view = (UIView*)entity;
    }
    
    if (depth == 0) {
        // only track these if this is a top level serialization - there is no need for these
        // properties if it is "in depth" serialization anyways
        [serializedView setObject:[self getPathForView:view] forKey:@"path"];
        
        NSString *viewControllerClassString = NSStringFromClass([[self viewControllerForView:view] class]);
        
        if (viewControllerClassString) {
            [serializedView setObject:viewControllerClassString forKey:@"viewController"];
        }
    }
    
    if ([view isKindOfClass:[UIPickerView class]]) {
        // it's a picker, it has selectedRowInComponent:-specific serialization
        UIPickerView *viewAsPickerView = (UIPickerView*)view;
        NSInteger numberOfComponents = [viewAsPickerView numberOfComponents];
        NSMutableArray *selectedRows = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < numberOfComponents; i++) {
            [selectedRows addObject:@([viewAsPickerView selectedRowInComponent:i])];
            [selectedRows addObject:@([viewAsPickerView selectedRowInComponent:i])];

        }
        [serializedView setObject:selectedRows forKey:@"selectedRows"];
    }
    
    if ([view isKindOfClass:[UISegmentedControl class]]) {
        UISegmentedControl *viewAsSegmentedControl = (UISegmentedControl*)view;
        
        [serializedView setObject:[viewAsSegmentedControl titleForSegmentAtIndex:viewAsSegmentedControl.selectedSegmentIndex] forKey:@"selectedSegmentTitle"];
    }
    
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *btn = (UIButton*)view;
        if([btn.titleLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0)
            [serializedView setObject:[btn.titleLabel text] forKey:@"text"];
    }

    
    for (NSString* propertyName in [self getPropertiesList:view]) {
        if ([excludedProperties containsObject:propertyName]) {
            // this property is excluded from tracking, continue
            continue;
        }
        if (isSecure && [excludedPropertiesForSecure containsObject:propertyName]) {
            // do not track secure texts
            continue;
        }
        if ([propertyName hasPrefix:@"_"]) {
            // this is, most likely, a "private" (sort) or technical
            // property, let's not track that
            continue;
        }
        
        id propertyValue;
        @try {
            propertyValue = [view valueForKey:propertyName];
            
        } @catch (NSException* ex) {
            #ifdef DEBUG
            NSLog(@"Failed to collect property value for property name \"%@\" with exception %@", propertyName, ex);
            #endif
            continue;
        }
        
        if (!propertyValue) {
            continue;
        }
        
        for (NSUInteger i = 0; i < [excludedTypesClasses count]; i++) {
            if ([propertyValue isKindOfClass:excludedTypesClasses[i]]) {
                // we don't want to track this class or any of its descendants
                continue;
            }
        }
        
        bool _trackCustomProperties = trackCustomProperties;
        
        NSString *uiViewType = [self getUIViewType:view];
        if ([ignoreCustomPropertiesForSubtypesOf containsObject:uiViewType]) {
            // we override tracking custom properties of this type as it is
            // a direct ancestor of one of the ignored ones
            _trackCustomProperties = NO;
        }
        
        NSDictionary* typeSubdict = [trackedTypesAndProperties objectForKey:uiViewType];
        
        NSString* typeString = nil;
        if (typeSubdict) {
            typeString = [typeSubdict objectForKey:propertyName];
        }
        if (!typeString) {
            // check common properties dict too
            typeString = [[trackedTypesAndProperties objectForKey:@"*"] objectForKey:propertyName];
        }
        
        if (typeString && ![typeString isEqualToString:@"nil"]) {
            id serializedPropValue = [self serializePropertyValue:propertyValue ofType:typeString withDepth:depth];
            
            if (serializedPropValue) {
                [serializedView setObject:serializedPropValue forKey:propertyName];
            }
        } else {
            if (!_trackCustomProperties && typeSubdict && !typeString) {
                // it's a custom property, we don't track those if flag is not specified
                continue;
            }
            
            NSString* propertyType;
            @try {
                propertyType = [self getTypeForProperty:propertyName inObject:view];
            } @catch (NSException* ex) {
                #ifdef DEBUG
                NSLog(@"Failed to get property type for property name \"%@\" with exception: %@", propertyName, ex);
                #endif
                continue;
            }
            
            id serializedPropValue = [self serializePropertyValue:propertyValue ofType:propertyType withDepth:depth];
            
            if (serializedPropValue) {
                [serializedView setObject:serializedPropValue forKey:propertyName];
            }
        }
    }
    
    return serializedView;
}

+ (NSDictionary*)serializeUIViewDerivative:(id)view {
    return [self serializeUIViewDerivative:view withDepth:0];
}

@end
