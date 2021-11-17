//
//  DBManager.m
//  Intempt
//
//  Created by Appsbee LLC on 03/02/21.
//  Copyright © 2021 Intempt. All rights reserved.
//

#import "DBManager.h"
#import "ModelEvent.h"

static DBManager *sharedInstance = nil;
//static sqlite3 *database = nil;
//static sqlite3_stmt *statement = nil;

@implementation DBManager

+ (DBManager*)shared {
    if (!sharedInstance) {
        sharedInstance = [[super allocWithZone:NULL] init];
        [sharedInstance createDB];
    }
    return sharedInstance;
}

- (BOOL)createDB {
    // Get the documents directory
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
        // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:
                    [docsDir stringByAppendingPathComponent: @"intempt.sqlite"]];
    NSLog(@"Intempt database path: %@",databasePath);
    
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO) {
        const char *dbpath = [databasePath UTF8String];
        sqlite3 *database = nil;
        if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
            char *errMsg;
            const char *sql_stmt =
            "create table if not exists interaction (id INTEGER PRIMARY KEY, content BLOB NOT NULL, event_type VARCHAR(50) NOT NULL, is_sync BOOLEAN DEFAULT 0)";
            
            if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                NSLog(@"Failed to create table: %s",sqlite3_errmsg(database));
            }
            sqlite3_close(database);
            return isSuccess;
        } else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
    }
    return isSuccess;
}

- (BOOL)insertAnalayticsData:(NSDictionary*)content withEventType:(NSString*)type  {
    BOOL status = NO;
    
    if (content.count == 0 || type.length == 0) {
        return status;
    }
    NSData *dataJson = [self convertDictionaryToData:content];
    if (dataJson == nil) {
        return status;
    }
    
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *database = nil;
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into interaction (id, content, event_type) values (NULL, ?, \"%@\")", type];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL) == SQLITE_OK) {
            int dataLength = (int)[dataJson length];
            sqlite3_bind_blob(statement, 1, [dataJson bytes], dataLength, SQLITE_STATIC);
            
            if (sqlite3_step(statement) == SQLITE_DONE) {
                status = YES;
            }
            else {
                status = NO;
                NSLog(@"Failed to insert: %s",sqlite3_errmsg(database));
            }
        }
        else {
            status = NO;
            NSLog(@"\nINSERT statement could not be prepared.");
        }
        sqlite3_reset(statement);
        if (sqlite3_finalize(statement) != SQLITE_OK) NSLog(@"SQL Error: %s",sqlite3_errmsg(database));
        sqlite3_close(database);
    }
    return status;
}

- (BOOL)updateRecordsWithEventId:(NSInteger)insertId withIsSync:(BOOL)status {
    BOOL updateStatus = NO;
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *database = nil;
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"update interaction set is_sync = \"%d\" where id=\"%ld\"", (status ? 1 : 0), insertId];
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_DONE) {
                updateStatus = YES;
            }
            else {
                updateStatus = NO;
                NSLog(@"Failed to delete: %s",sqlite3_errmsg(database));
            }
        }
        else {
            NSLog(@"\nDELETE statement could not be prepared.");
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return updateStatus;
}

- (BOOL)deleteRecordsWithEventId:(NSInteger)insertId {
    BOOL updateStatus = NO;
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *database = nil;
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"delete from interaction where id=\"%ld\"", insertId];
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_DONE) {
                updateStatus = YES;
            }
            else {
                updateStatus = NO;
                NSLog(@"Failed to delete: %s",sqlite3_errmsg(database));
            }
        }
        else {
            NSLog(@"\nDELETE statement could not be prepared.");
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return updateStatus;
}

- (NSArray*)fetchAnalayticsDataWithSync:(BOOL)isSync useLimit:(BOOL)status withBatchSize:(int)limit {
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *database = nil;
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSMutableArray *resultArray = [[NSMutableArray alloc] init];
        NSString *querySQL = [NSString stringWithFormat:@"select id, content, event_type from interaction where is_sync=\"%d\" order by id ASC %@",(isSync ? 1 : 0), (status ? [NSString stringWithFormat:@" limit %d",limit] : @"")];
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                
                NSString *insertId = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
                
                const void *blobBytes = sqlite3_column_blob(statement, 1);
                int blobBytesLength = sqlite3_column_bytes(statement, 1); // Count the number of bytes in the BLOB.
                NSData *dataContent = [NSData dataWithBytes:blobBytes length:blobBytesLength];
                NSDictionary *dictContent = [self convertDataToDictionary:dataContent];
                
                NSString *eventyType = [[NSString alloc] initWithUTF8String:
                                     (const char *) sqlite3_column_text(statement, 2)];
                
                if (dictContent != nil) {
                    ModelEvent *modelEvent = [[ModelEvent alloc] initWithEventId:insertId withContent:dictContent withType:eventyType];
                    [resultArray addObject:modelEvent];
                }
            }
            sqlite3_finalize(statement);
            sqlite3_close(database);
            return resultArray;
        }
        else {
            NSLog(@"\nSELECT statement could not be prepared.");
            sqlite3_close(database);
        }
    }
    return nil;
}


- (BOOL)deleteAnalayticsDataWithSync:(BOOL)isSync {
    BOOL status = NO;
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *database = nil;
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:@"delete from interaction where is_sync=\"%d\"",(isSync ? 1 : 0)];
        const char *query_stmt = [querySQL UTF8String];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_DONE) {
                status = YES;
            }
            else {
                status = NO;
                NSLog(@"Failed to delete: %s",sqlite3_errmsg(database));
            }
        }
        else {
            NSLog(@"\nDELETE statement could not be prepared.");
        }
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return status;
}

# pragma mark - Helper Methods

-(NSData*)convertDictionaryToData:(NSDictionary*)dict {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    if (error!= nil) {
        NSLog(@"Failed to convert to data: %@",[error localizedDescription]);
        return nil;
    }
    else {
        return jsonData;
    }
}

- (NSDictionary*)convertDataToDictionary:(NSData*)data {
    NSError *error = nil;
    NSDictionary *dictJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error!= nil) {
        NSLog(@"Failed to convert to dictionary: %@",[error localizedDescription]);
        return nil;
    }
    else {
        return dictJson;
    }
}

@end
