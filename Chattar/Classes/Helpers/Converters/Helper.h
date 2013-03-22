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
+(BOOL)checkSymbol:(NSString*)symbol inString:(NSString*)string;
+(NSString*)createTitleFromXMPPTitle:(NSString*)result;
+ (void)addQuoteDataToAnnotation:(UserAnnotation *)annotation quotationText:(NSString*)quoteText;
@end
