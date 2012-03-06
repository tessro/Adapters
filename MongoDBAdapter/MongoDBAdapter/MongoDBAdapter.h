//
//  MongoDBAdapter.h
//  MongoDBAdapter
//
//  Created by Mattt Thompson on 12/03/05.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBAdapter.h"


@interface MongoDBAdapter : NSObject <DBAdapter>
@end

@interface MongoDBConnection : NSObject <DBConnection>

- (id <DBResultSet>)runCommand:(id)command 
                    onDatabase:(id <DBDatabase>)database
                         error:(NSError **)error;

@end

@interface MongoDBDatabase : NSObject <DBDatabase>

- (id)initWithConnection:(MongoDBConnection *)connection
              attributes:(NSDictionary *)attributes;

@end

@interface MongoDBCollection : NSObject <DBDataSource, DBExplorableDataSource, DBQueryableDataSource>

@property (nonatomic, readonly) NSString *namespace;

- (id)initWithDatabase:(MongoDBDatabase *)database
            attributes:(NSDictionary *)attributes;

@end

@interface MongoDBResultSet : NSObject <DBResultSet>

- (id)initWithCursor:(void *)cursor;

@end

@interface MongoDBDocument :  NSObject <DBRecord>

@property (nonatomic, strong, readonly) NSString *key;
@property (nonatomic, strong, readonly) id value;

- (id)initWithDictionary:(NSDictionary *)attributes;

@end