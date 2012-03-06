//
//  SQLiteAdapter.h
//  SQLiteAdapter
//
//  Created by Mattt Thompson on 12/03/05.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SQLAdapter.h"

extern NSString * const PostgreSQLErrorDomain;

#pragma mark -

@interface SQLiteAdapter : NSObject <DBAdapter>

@end

@interface SQLiteConnection : NSObject <SQLConnection>

@end

#pragma mark -

@interface SQLiteDatabase : NSObject <SQLDatabase>
@end

#pragma mark -

@interface SQLiteTable : NSObject <SQLTable>
@end

#pragma mark -

@interface SQLiteField : NSObject <SQLField>

+ (id <SQLField>)fieldInSQLiteResult:(void *)result 
                             atIndex:(NSUInteger)fieldIndex;

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding;

@end

#pragma mark -

@interface SQLiteTuple : NSObject <SQLTuple>

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues;

@end

#pragma mark -

@interface SQLiteResultSet : NSObject <SQLResultSet>

- (id)initWithSQLiteStatement:(void *)result;

@end
