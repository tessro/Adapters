# Writing a Database Adapter

Database adapters for Induction are designed to be easy to write. Adapters are packaged as bundles, with their primary class implementing the `DBAdapter` protocol. Here is a rundown of the roles and responsibilities of the adapter protocols (note, these interfaces are not final, and subject to evolve and change as the project matures):

## DBAdapter

Specifies a URL scheme, validates connection URLs and creates connections.

``` objective-c
@protocol DBAdapter <NSObject>
+ (NSString *)primaryURLScheme;
+ (BOOL)canConnectWithURL:(NSURL *)url;
+ (id <DBConnection>)connectionWithURL:(NSURL *)url 
                                 error:(NSError **)error;
@end
```

## DBConnection

Initializes and manages a connection client, most often a C interface to a system library.

``` objective-c
@protocol DBConnection <NSObject>
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSArray *databases;

- (id)initWithURL:(NSURL *)url;

- (BOOL)open;
- (BOOL)close;
- (BOOL)reset;
@end
```

## DBDatabase

Represents an organized collection of data, most often corresponding to a database in the target platform. 

It's principle responsibility is to populate the source list on the left side of the connection window.

``` objective-c
@protocol DBDatabase <NSObject>
@property (nonatomic, readonly) id <DBConnection> connection;
@property (nonatomic, readonly) NSOrderedSet *dataSourceGroupNames;

- (NSArray *)dataSourcesForGroupNamed:(NSString *)groupName;
@end
```

## DBDataSource

Following the [interpretation used by Yahoo YUI](http://developer.yahoo.com/yui/datasource/), this is "an abstract representation of a live set of data that presents a common predictable API for other objects to interact with." Examples of this include SQL tables, MongoDB collections, collections of Redis keys according to their type, etc.

Data sources have their responsibilities split across three different protocols, representing the "Explore", "Query", and "Visualize" features of the application. By conforming to its respective protocol, the adapter makes itself available for that feature.

``` objective-c
@protocol DBDataSource <NSObject>
- (NSUInteger)numberOfRecords;
@end
```

### DBExplorableDataSource

``` objective-c
@protocol DBExplorableDataSource <NSObject>
- (id <DBResultSet>)resultSetForRecordsAtIndexes:(NSIndexSet *)indexes                                                          
                                           error:(NSError **)error;
@end
```

### DBQueryableDataSource

``` objective-c
@protocol DBQueryableDataSource <NSObject>
- (id <DBResultSet>)resultSetForQuery:(NSString *)query 
                                error:(NSError **)error;
@end
```

### DBVisualizableDataSource

```objective-c
@protocol DBVisualizableDataSource <NSObject>
- (id <DBResultSet>)resultSetForDimension:(NSExpression *)dimension
                                 measures:(NSArray *)measures
                                    error:(NSError **)error;
@end
```

## DBResultSet

Perhaps the most significant part of an adapter, this object represents a result set of data, and drives the display of information in tables and outlines. Whereas a SQL table is a `DBDataSource`, the first page of 1000 results would be a `DBResultSet`, and it is the result set that is displayed.

``` objective-c
@protocol DBResultSet <NSObject>
- (NSUInteger)numberOfRecords;
- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes;

- (NSUInteger)numberOfFields;
- (NSString *)identifierForTableColumnAtIndex:(NSUInteger)index;
@optional
- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index;
- (NSCell *)dataCellForTableColumnAtIndex:(NSUInteger)index;
- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index;
@end
```

## DBRecord

Records correspond to rows, or individual documents in the result set, and are represented by an object conforming to the `DBRecord` protocol. `DBResultSet` fields correspond to columns or values, which are strings that are passed to `DBRecord` objects using `valueForKey:`.

Adapters to graph or document databases can optionally specify the child records, which can be expanded using disclosure indicators in an outline view.

``` objective-c
@protocol DBRecord <NSObject>
- (id)valueForKey:(NSString *)key;
@optional
@property (nonatomic, readonly) NSArray *children;
@end
```
