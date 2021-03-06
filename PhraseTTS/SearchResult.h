//
//  SearchResult.h
//  PhraseTTS
//
//  Created by cclaan on 4/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMResultSet.h"



@interface SearchResult : NSObject {
	
	NSString * body;
	int uses;
	
}


@property (readwrite) int uses;

@property (readwrite) int rowid;

@property (nonatomic,retain) NSString * body;

-(void) incrementUsesAndSave;
-(BOOL) insertIntoDb;
-(BOOL) checkIfExistsAndPopulateIfSo;
-(BOOL) removeFromDb;


+(SearchResult*) searchResultFromResultSet:(FMResultSet*) rs;

+(NSArray*) sortedSearchForQuery:(NSString*)query;
+(NSArray*) getTopUsedPhrases;
+(NSArray*) getWordCompletions:(NSString*)word;

+(void) clearSearchHistory;

-(void) copy:(SearchResult *)sr;

@end






