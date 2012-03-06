//
//  SQLiteAdapter.m
//  SQLiteAdapter
//
//  Created by Mattt Thompson on 12/03/05.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SQLiteAdapter.h"

#import <sqlite3.h>

@implementation SQLiteAdapter

+ (NSString *)primaryURLScheme {
    return @"sqlite";
}

+ (BOOL)canConnectWithURL:(NSURL *)url {
    return [[NSSet setWithObjects:@"sqlite", @"sqlite3", @"file", nil] containsObject:[url scheme]];    
}

+ (id <DBConnection>)connectionWithURL:(NSURL *)url 
                                 error:(NSError **)error
{
    return [[SQLiteConnection alloc] initWithURL:url];
}

@end

#pragma mark -

@interface SQLiteConnection () {
@public
    sqlite3 *_sqlite3_connection;
@private
    __strong NSURL *_url;
}

@end

@implementation SQLiteConnection
@synthesize url = _url;
@dynamic databases;

- (void)dealloc {
    if (_sqlite3_connection) {
        _sqlite3_connection = NULL;
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
    
    _sqlite3_connection = NULL;
    
    int code = sqlite3_open([[_url absoluteString] UTF8String], &_sqlite3_connection);

    if (code != 0) {
        NSLog(@"Error: %d", code);
        return NO;
    }
    
    return YES;
}

- (BOOL)close {
    sqlite3_close(_sqlite3_connection);
	return YES;
}

- (BOOL)reset {
    return NO;
}

- (id <SQLResultSet>)executeSQL:(NSString *)SQL 
                          error:(NSError *__autoreleasing *)error 
{    
    sqlite3_stmt *sqlite3_statement = NULL;
    sqlite3_prepare_v2(_sqlite3_connection, [SQL UTF8String], -1, &sqlite3_statement, NULL);
    
    if (sqlite3_statement) {
        return [[SQLiteResultSet alloc] initWithSQLiteStatement:sqlite3_statement];
    } else {
        return nil;
    }
}


- (NSArray *)databases {
    SQLiteDatabase *database = [[SQLiteDatabase alloc] initWithConnection:self name:[_url path] stringEncoding:NSUTF8StringEncoding];
    
    return [NSArray arrayWithObject:database];
}

@end

#pragma mark -

@interface SQLiteDatabase () {
@private
    __strong SQLiteConnection *_connection;
    __strong NSString *_name;
    __strong NSArray *_tables;
    NSStringEncoding _stringEncoding;
}
@end

@implementation SQLiteDatabase
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
    
    SQLiteResultSet *resultSet = [_connection executeSQL:@"SELECT name FROM (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master) WHERE type == 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name ASC" error:nil];
    NSString *fieldName = [[[resultSet fields] lastObject] name];
    NSMutableArray *mutableTables = [NSMutableArray array];
    [[resultSet tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SQLiteTable *table = [[SQLiteTable alloc] initWithDatabase:self name:[(SQLiteTuple *)obj valueForKey:fieldName] stringEncoding:NSUTF8StringEncoding];
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

@interface SQLiteTable () {
@private
    __strong SQLiteDatabase *_database;
    __strong NSString *_name;
    NSStringEncoding _stringEncoding;
}
@end

@implementation SQLiteTable
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

@interface SQLiteField () {
@private
    NSUInteger _index;
    __strong NSString *_name;
    DBValueType _type;
    NSUInteger _size;
}
@end

@implementation SQLiteField
@synthesize index = _index;
@synthesize name = _name;
@synthesize type = _type;
@synthesize size = _size;

+ (SQLiteField *)fieldInSQLiteResult:(void *)result 
                             atIndex:(NSUInteger)fieldIndex 
{
    SQLiteField *field = [[SQLiteField alloc] init];
    field->_index = fieldIndex;
    field->_name = [NSString stringWithUTF8String:sqlite3_column_name(result, (int)fieldIndex)];
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

@interface SQLiteTuple () {
@private
    NSUInteger _index;
    __strong NSDictionary *_valuesKeyedByFieldName;
}
@end

@implementation SQLiteTuple
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

@interface SQLiteResultSet () {
@private
    NSUInteger _tuplesCount;
    NSUInteger _fieldsCount;
    __strong NSArray *_fields;
    __strong NSDictionary *_fieldsKeyedByName;
    __strong NSArray *_tuples;
}

- (id)tupleValueForStatement:(void *)statement 
                atFieldIndex:(NSUInteger)fieldIndex;
@end

@implementation SQLiteResultSet
@synthesize fields = _fields;
@synthesize tuples = _tuples;

- (id)initWithSQLiteStatement:(void *)result {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _fieldsCount = sqlite3_column_count(result);
    
    NSMutableArray *mutableFields = [[NSMutableArray alloc] initWithCapacity:_fieldsCount];
    NSIndexSet *fieldIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_fieldsCount)];
    [fieldIndexSet enumerateIndexesWithOptions:NSEnumerationConcurrent usingBlock:^(NSUInteger fieldIndex, BOOL *stop) {
        SQLiteField *field = [SQLiteField fieldInSQLiteResult:result atIndex:fieldIndex];
        [mutableFields addObject:field];
    }];
    _fields = mutableFields;
    
    NSMutableDictionary *mutableKeyedFields = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
    for (SQLiteField *field in _fields) {
        [mutableKeyedFields setObject:field forKey:field.name];
    }
    _fieldsKeyedByName = mutableKeyedFields;
    
    NSMutableArray *mutableTuples = [[NSMutableArray alloc] init];
    sqlite3_reset(result);
    int code = sqlite3_step(result);
    while (code == SQLITE_ROW) {
        NSMutableDictionary *mutableKeyedTupleValues = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
        for (SQLiteField *field in _fields) {
            id value = [self tupleValueForStatement:result atFieldIndex:[field index]];
            [mutableKeyedTupleValues setObject:value forKey:[field name]];
        }
        SQLiteTuple *tuple = [[SQLiteTuple alloc] initWithValuesKeyedByFieldName:mutableKeyedTupleValues];
        [mutableTuples addObject:tuple];
        code = sqlite3_step(result);
    }
    
    _tuples = mutableTuples;
    _tuplesCount = [_tuples count];
    
    sqlite3_finalize(result);
    
    return self;
}

- (id)tupleValueForStatement:(void *)statement 
                atFieldIndex:(NSUInteger)fieldIndex
{
    const char *bytes = (const char *)sqlite3_column_text(statement, (int)fieldIndex);
    if (bytes == NULL) {
        return [NSNull null];
    } else {
        return [[NSString alloc] initWithUTF8String:bytes];
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
    SQLiteField *field = [_fields objectAtIndex:index];
    return [field name];
}

- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index {
    SQLiteField *field = [_fields objectAtIndex:index];
    return [field type];
}

- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index {
    SQLiteField *field = [_fields objectAtIndex:index];
    if ([field type] == DBStringValue) {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES selector:@selector(localizedStandardCompare:)];
    } else {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES];
    }
}

@end
