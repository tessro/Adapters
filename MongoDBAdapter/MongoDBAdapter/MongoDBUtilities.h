//
//  MongoDBUtilities.h
//  MongoDBAdapter
//
//  Created by Mattt Thompson on 12/03/06.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#import "bson.h"
#import "mongo.h"
#import "md5.h"

extern NSDictionary * NSDictionaryFromBSON(bson *bson);
extern NSObject * NSObjectFromBSONIterator(bson_iterator *iterator);
extern NSArray * NSArrayFromBSONIterator(bson_iterator *iterator);
extern NSDictionary * NSDictionaryFromBSONIterator(bson_iterator *iterator);

extern void BSONBufferFillFromDictionary(bson_buffer *buffer, NSDictionary *dictionary);
