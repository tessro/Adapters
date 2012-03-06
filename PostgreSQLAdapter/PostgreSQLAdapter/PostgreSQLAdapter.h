//
//  PostgreSQL.h
//  NoSQL
//
//  Created by Mattt Thompson on 12/01/24.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLAdapter.h"

extern NSString * const PostgreSQLErrorDomain;

#pragma mark -

@interface PostgreSQLAdapter : NSObject <DBAdapter>

@end

@interface PostgreSQLConnection : NSObject <SQLConnection>

@end

#pragma mark -

@interface PostgreSQLDatabase : NSObject <SQLDatabase>
@end

#pragma mark -

@interface PostgreSQLTable : NSObject <SQLTable>
@end

#pragma mark -

@interface PostgreSQLField : NSObject <SQLField>

+ (PostgreSQLField *)fieldInPGResult:(void *)pgresult 
                             atIndex:(NSUInteger)fieldIndex;

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding;

@end

#pragma mark -

@interface PostgreSQLTuple : NSObject <SQLTuple>

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues;

@end

#pragma mark -

@interface PostgreSQLResultSet : NSObject <SQLResultSet>

- (id)initWithPGResult:(void *)pgresult;

@end
