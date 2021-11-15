//
//  NSMutableArray+QueueAdditions.h
//  intempt
//
//  Created by Intempt on 18/03/20.
//  Copyright © 2020 Intempt. All rights reserved.
//

@import Foundation;

@interface NSMutableArray (QueueAdditions)

- (id)dequeue;
- (void)enqueue:(id)obj;
- (id)peek:(int)index;
- (id)peekHead;
- (id)peekTail;
- (BOOL)empty;

@end
