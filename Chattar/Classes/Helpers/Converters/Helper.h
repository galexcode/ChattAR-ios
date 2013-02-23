//
//  Helper.h
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject
+(BOOL)isStringCorrect:(NSString*)stringToCheck;
+(NSArray*)sortArray:(NSArray*) array dependingOnField:(NSString*)fieldName inAscendingOrder:(BOOL)ascending;
@end
