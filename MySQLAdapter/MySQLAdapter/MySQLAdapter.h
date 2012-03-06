//
//  MySQL.h
//  Kirin
//
//  Created by Mattt Thompson on 12/01/31.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLAdapter.h"

@interface MySQLAdapter : NSObject <DBAdapter>
@end

#pragma mark -

@interface MySQLConnection : NSObject <SQLConnection>
@end

#pragma mark -

@interface MySQLDatabase : NSObject <SQLDatabase>
@end

#pragma mark -

@interface MySQLTable : NSObject <SQLTable>
@end

#pragma mark -

@interface MySQLField : NSObject <SQLField>

+ (MySQLField *)fieldInMySQLResult:(void *)result 
                           atIndex:(NSUInteger)fieldIndex;

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding;

@end

#pragma mark -

@interface MySQLTuple : NSObject <SQLTuple>

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues;

@end

#pragma mark -

@interface MySQLResultSet : NSObject <SQLResultSet>

- (id)initWithMySQLResult:(void *)result;

@end
