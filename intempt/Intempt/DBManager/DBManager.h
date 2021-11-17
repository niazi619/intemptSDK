//
//  DBManager.h
//  Intempt
//
//  Created by Appsbee LLC on 03/02/21.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>


NS_ASSUME_NONNULL_BEGIN

@interface DBManager : NSObject {
    NSString *databasePath;
}

+ (DBManager*)shared;
- (BOOL)createDB;
- (BOOL)insertAnalayticsData:(NSDictionary*)content withEventType:(NSString*)type;
- (BOOL)updateRecordsWithEventId:(NSInteger)insertId withIsSync:(BOOL)status;
- (BOOL)deleteRecordsWithEventId:(NSInteger)insertId;
- (NSArray*)fetchAnalayticsDataWithSync:(BOOL)isSync useLimit:(BOOL)status withBatchSize:(int)limit;
- (BOOL)deleteAnalayticsDataWithSync:(BOOL)isSync;

@end

NS_ASSUME_NONNULL_END
