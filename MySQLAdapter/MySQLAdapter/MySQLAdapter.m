//
//  MySQL.m
//  Kirin
//
//  Created by Mattt Thompson on 12/01/31.
//  Copyright (c) 2012年 Heroku. All rights reserved.
//

#import "MySQLAdapter.h"

#import "mysql.h"

@implementation MySQLAdapter

+ (NSString *)primaryURLScheme {
    return @"mysql";
}

+ (BOOL)canConnectWithURL:(NSURL *)url {
    return [[url scheme] isEqualToString:[self primaryURLScheme]];
}

+ (id <DBConnection>)connectionWithURL:(NSURL *)url 
                                 error:(NSError **)error
{
    return [[MySQLConnection alloc] initWithURL:url];
}

@end

#pragma mark -

@interface MySQLConnection () {
@public
    MYSQL *_mysql_connection;
@private
    __strong NSURL *_url;
}

@end

@implementation MySQLConnection
@synthesize url = _url;
@dynamic databases;

- (void)dealloc {
    if (_mysql_connection) {
        mysql_close(_mysql_connection);
        _mysql_connection = NULL;
    }
}

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _url = url;
    
    return self;
}

- (BOOL)open {
	[self close];
    
	mysql_close(_mysql_connection);
    
    _mysql_connection = mysql_init(NULL);
    
    const char *host = [[_url host] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *user = [[_url user] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *password = [[_url password] cStringUsingEncoding:NSUTF8StringEncoding];
    const char *database = [[_url lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned int port = [[_url port] unsignedIntValue];
    const char *socket = MYSQL_UNIX_ADDR;
    
    mysql_real_connect(_mysql_connection, host, user, password, database, port, socket, 0);
    
    return YES;
}

- (BOOL)close {
    //	if (_pgconn == nil) { return NO; }
    //	if (isConnected == NO) { return NO; }
    //	
    //	[self appendSQLLog:[NSString stringWithString:@"Disconnected from database.\n"]];
	mysql_close(_mysql_connection);
    //	_pgconn = nil;
    //	isConnected = NO;
	return YES;
}

- (BOOL)reset {
    mysql_refresh(_mysql_connection, 0);
    return mysql_stat(_mysql_connection) == MYSQL_STATUS_READY;
}

- (id <SQLResultSet>)executeSQL:(NSString *)SQL 
                          error:(NSError *__autoreleasing *)error 
{
    MYSQL_RES *myql_result = nil;
    
    int code = mysql_query(_mysql_connection, [SQL cStringUsingEncoding:NSUTF8StringEncoding]);
    if (code == 0) {
		if (mysql_field_count(_mysql_connection) != 0) {
			myql_result = mysql_store_result(_mysql_connection);
		} else {
			return nil;
		}
	} else {
        //		if ([SQL length] < 1024) {
        //			NSLog (@"Problem in queryString error code is : %d, query is : %@-\n", theQueryCode, query);
        //		} else {
        //			NSLog (@"Problem in queryString error code is : %d, query is (truncated) : %@-\n", theQueryCode, [query substringToIndex:1024]);
        //		}
        //		
        //        NSLog(@"Error message is : %@\n", [self getLastErrorMessage]);
		
        return nil;
	}
    
    return [[MySQLResultSet alloc] initWithMySQLResult:myql_result];
}


- (NSArray *)databases {
    MySQLResultSet *resultSet = [[MySQLResultSet alloc] initWithMySQLResult:mysql_list_dbs(_mysql_connection, NULL)]; 
    NSMutableArray *mutableDatabases = [[NSMutableArray alloc] init];
    [[resultSet tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MySQLDatabase *database = [[MySQLDatabase alloc] initWithConnection:self name:[(MySQLTuple *)obj valueForKey:@"Database"] stringEncoding:NSUTF8StringEncoding];
        [mutableDatabases addObject:database];
    }];
    
    return mutableDatabases;
}

@end

#pragma mark -

@interface MySQLDatabase () {
@private
    __strong MySQLConnection *_connection;
    __strong NSString *_name;
    __strong NSArray *_tables;
    NSStringEncoding _stringEncoding;
}
@end

@implementation MySQLDatabase
@synthesize connection = _connection;
@synthesize name = _name;
@synthesize stringEncoding = _stringEncoding;
@synthesize tables = _tables;

- (id)initWithConnection:(id<SQLConnection>)connection name:(NSString *)name stringEncoding:(NSStringEncoding)stringEncoding 
{
    self = [super init];
    if (!self) {
        return nil;
    }
        
    _connection = connection;
    _name = name;
    _stringEncoding = NSUTF8StringEncoding;
    
    MySQLResultSet *resultSet = [[MySQLResultSet alloc] initWithMySQLResult:mysql_list_tables(_connection->_mysql_connection, NULL)];
    NSString *fieldName = [[[resultSet fields] lastObject] name];
    NSMutableArray *mutableTables = [NSMutableArray array];
    [[resultSet tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MySQLTable *table = [[MySQLTable alloc] initWithDatabase:self name:[(MySQLTuple *)obj valueForKey:fieldName] stringEncoding:NSUTF8StringEncoding];
        [mutableTables addObject:table];
    }];
    
    _tables = mutableTables;
    
    return self;
}

- (NSString *)description {
    return _name;
}

- (NSOrderedSet *)dataSourceGroupNames {
    return [NSOrderedSet orderedSetWithObject:NSLocalizedString(@"Tables", nil)];
}

- (NSArray *)dataSourcesForGroupNamed:(NSString *)groupName {
    return _tables;
}

@end

#pragma mark -

@interface MySQLTable () {
@private
    __strong MySQLDatabase *_database;
    __strong NSString *_name;
    NSStringEncoding _stringEncoding;
}
@end

@implementation MySQLTable
@synthesize name = _name;
@synthesize stringEncoding = _stringEncoding;

- (id)initWithDatabase:(id<SQLDatabase>)database 
                  name:(NSString *)name 
        stringEncoding:(NSStringEncoding)stringEncoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _database = database;
    _name = name;
    _stringEncoding = stringEncoding;
    
    return self;
}

- (NSString *)description {
    return _name;
}

- (id <DBResultSet>)resultSetForRecordsAtIndexes:(NSIndexSet *)indexes error:(NSError *__autoreleasing *)error {
    return [[_database connection] executeSQL:[NSString stringWithFormat:@"SELECT * FROM %@ LIMIT %d OFFSET %d ", _name, [indexes count], [indexes firstIndex]] error:error];
}

- (id<DBResultSet>)resultSetForQuery:(NSString *)query error:(NSError *__autoreleasing *)error {
    return [[_database connection] executeSQL:query error:error];
}

- (NSUInteger)numberOfRecords {
    return [[[[[[_database connection] executeSQL:[NSString stringWithFormat:@"SELECT COUNT(*) as count FROM %@", _name] error:nil] recordsAtIndexes:[NSIndexSet indexSetWithIndex:0]] lastObject] valueForKey:@"count"] integerValue]; 
}

@end

#pragma mark -

@interface MySQLField () {
@private
    NSUInteger _index;
    __strong NSString *_name;
    DBValueType _type;
    NSUInteger _size;
}
@end

@implementation MySQLField
@synthesize index = _index;
@synthesize name = _name;
@synthesize type = _type;
@synthesize size = _size;

+ (MySQLField *)fieldInMySQLResult:(void *)result 
                           atIndex:(NSUInteger)fieldIndex 
{
    MySQLField *field = [[MySQLField alloc] init];
    field->_index = fieldIndex;
    
    MYSQL_FIELD *myfield = mysql_fetch_field_direct(result, (int)fieldIndex);
    field->_name = [NSString stringWithCString:myfield->name encoding:NSUTF8StringEncoding];
    
    field->_type = DBStringValue;
     
    return field;
}

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding 
{
    return [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];    
}

@end

#pragma mark -

@interface MySQLTuple () {
@private
    NSUInteger _index;
    __strong NSDictionary *_valuesKeyedByFieldName;
}
@end

@implementation MySQLTuple
@synthesize index = _index;

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _valuesKeyedByFieldName = keyedValues;
    
    return self;
}

- (id)valueForKey:(NSString *)key {
    return [_valuesKeyedByFieldName objectForKey:key];
}

@end

#pragma mark -

@interface MySQLResultSet () {
@private
    MYSQL_RES *_mysql_result;
    NSUInteger _tuplesCount;
    NSUInteger _fieldsCount;
    __strong NSArray *_fields;
    __strong NSDictionary *_fieldsKeyedByName;
    __strong NSArray *_tuples;
}

- (id)tupleValueAtIndex:(NSUInteger)tupleIndex 
          forFieldNamed:(NSString *)fieldName;
@end

@implementation MySQLResultSet
@synthesize fields = _fields;
@synthesize tuples = _tuples;

- (void)dealloc {
    if (_mysql_result) {
        _mysql_result = NULL;
    }    
}

- (id)initWithMySQLResult:(void *)result {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _mysql_result = result;
    _tuplesCount = mysql_num_rows(_mysql_result);
    _fieldsCount = mysql_num_fields(_mysql_result);
    
    NSMutableArray *mutableFields = [[NSMutableArray alloc] initWithCapacity:_fieldsCount];
    NSIndexSet *fieldIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_fieldsCount)];
    [fieldIndexSet enumerateIndexesWithOptions:NSEnumerationConcurrent usingBlock:^(NSUInteger fieldIndex, BOOL *stop) {
        MySQLField *field = [MySQLField fieldInMySQLResult:result atIndex:fieldIndex];
        [mutableFields addObject:field];
    }];
    _fields = mutableFields;
    
    NSMutableDictionary *mutableKeyedFields = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
    for (MySQLField *field in _fields) {
        [mutableKeyedFields setObject:field forKey:field.name];
    }
    _fieldsKeyedByName = mutableKeyedFields;
    
    NSMutableArray *mutableTuples = [[NSMutableArray alloc] initWithCapacity:_tuplesCount];
    NSIndexSet *tupleIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _tuplesCount)];
    NSArray *fieldNames = [_fieldsKeyedByName allKeys];
    
    [tupleIndexSet enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger tupleIndex, BOOL *stop) {
        NSMutableDictionary *mutableKeyedTupleValues = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
        [fieldNames enumerateObjectsWithOptions:0 usingBlock:^(id fieldName, NSUInteger idx, BOOL *stop) {
            id value = [self tupleValueAtIndex:tupleIndex forFieldNamed:fieldName];
            [mutableKeyedTupleValues setObject:value forKey:fieldName];
        }];
        MySQLTuple *tuple = [[MySQLTuple alloc] initWithValuesKeyedByFieldName:mutableKeyedTupleValues];
        [mutableTuples addObject:tuple];
    }];
    
    _tuples = mutableTuples;
    
    return self;
}

- (id)tupleValueAtIndex:(NSUInteger)tupleIndex 
          forFieldNamed:(NSString *)fieldName 
{
    
    mysql_data_seek(_mysql_result, tupleIndex);
    MYSQL_ROW row = mysql_fetch_row(_mysql_result);
    
    NSUInteger fieldIndex = [[_fieldsKeyedByName objectForKey:fieldName] index];;
    if (row[fieldIndex] != NULL) {
        return [NSString stringWithCString:row[fieldIndex] encoding:NSUTF8StringEncoding];
    } else {
        return [NSNull null];
    }
}

- (NSUInteger)numberOfFields {
    return _fieldsCount;
}

- (NSUInteger)numberOfRecords {
    return _tuplesCount;
}

- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes {
    return [_tuples objectsAtIndexes:indexes];
}

- (NSString *)identifierForTableColumnAtIndex:(NSUInteger)index {
    MySQLField *field = [_fields objectAtIndex:index];
    return [field name];
}

- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index {
    MySQLField *field = [_fields objectAtIndex:index];
    return [field type];
}

- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index {
    MySQLField *field = [_fields objectAtIndex:index];
    if ([field type] == DBStringValue) {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES selector:@selector(localizedStandardCompare:)];
    } else {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES];
    }
}

@end
