#import <Foundation/Foundation.h>
#import "DBAdapter.h"

@class RedisResultSet;

@interface RedisAdapter : NSObject <DBAdapter>

@end

@interface RedisConnection : NSObject <DBConnection, DBDatabase>

@end

@interface RedisDataSource : NSObject <DBDataSource>

- (id)initWithName:(NSString *)name
              keys:(NSArray *)keys
        connection:(RedisConnection *)connection;

@end

#pragma mark -

@interface RedisResultSet : NSObject <DBResultSet>

- (id)initWithRecords:(NSArray *)records;

@end

#pragma mark -

@interface RedisKeyValuePair : NSObject <DBRecord>

- (id)initWithKey:(NSString *)key
            value:(NSString *)value;

@end

@interface RedisRecord : NSObject <DBRecord>

- (id)initWithKey:(NSString *)key
       connection:(RedisConnection *)connection;

@end

@interface RedisHash : RedisRecord

@end

@interface RedisList : RedisRecord

@end

@interface RedisSet : RedisRecord

@end

@interface RedisSortedSet : RedisRecord

@end

@interface RedisString : RedisRecord

@end