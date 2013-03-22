//
//  Helper.m
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import "Helper.h"

@implementation Helper

+ (BOOL)isStringCorrect:(NSString*)stringToCheck{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [stringToCheck stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed length] == 0) {
        return NO;
    }
    return YES;
}

+ (NSArray*)sortArray:(NSArray*) array dependingOnField:(NSString*)fieldName inAscendingOrder:(BOOL)ascending{
    
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey:fieldName ascending:ascending];
    array = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    NSArray* newArray = array.mutableCopy;
    return [newArray autorelease];
}

+ (BOOL)checkSymbol:(NSString *)symbol inString:(NSString *)string{
    NSCharacterSet* characterSet = [NSCharacterSet characterSetWithCharactersInString:symbol];
    if ([string rangeOfCharacterFromSet:characterSet].location == NSNotFound) {
        return NO;
    }
    return YES;
}

+ (NSString*)createTitleFromXMPPTitle:(NSString*)xmppTitle{
    NSCharacterSet* characterSet = [NSCharacterSet characterSetWithCharactersInString:@"@"];
    return [[xmppTitle componentsSeparatedByCharactersInSet:characterSet] objectAtIndex:0];
}


// Add Quote data to annotation
+ (void)addQuoteDataToAnnotation:(UserAnnotation *)annotation quotationText:(NSString*)quoteText{
    // get quoted geodata
    annotation.userStatus = [quoteText substringFromIndex:[quoteText rangeOfString:quoteDelimiter].location+1];
    
    // Author FB id
    NSString* authorFBId = [[quoteText substringFromIndex:6] substringToIndex:[quoteText rangeOfString:nameIdentifier].location-6];
    annotation.quotedUserFBId = authorFBId;
    
    // Author name
    NSString* authorName = [[quoteText substringFromIndex:[quoteText rangeOfString:nameIdentifier].location+6] substringToIndex:[[quoteText substringFromIndex:[quoteText rangeOfString:nameIdentifier].location+6] rangeOfString:dateIdentifier].location];
    annotation.quotedUserName = authorName;
    
    // origin Message date
    NSString* date = [[quoteText substringFromIndex:[quoteText rangeOfString:dateIdentifier].location+6] substringToIndex:[[quoteText substringFromIndex:[quoteText rangeOfString:dateIdentifier].location+6] rangeOfString:photoIdentifier].location];
    //
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss Z"];
    annotation.quotedMessageDate = [formatter dateFromString:date];
    [formatter release];
    
    // authore photo
    NSString* photoLink = [[quoteText substringFromIndex:[quoteText rangeOfString:photoIdentifier].location+7] substringToIndex:[[quoteText substringFromIndex:[quoteText rangeOfString:photoIdentifier].location+7] rangeOfString:qbidIdentifier].location];
    annotation.quotedUserPhotoURL = photoLink;
    
    // Authore QB id
    NSString* authorQBId = [[quoteText substringFromIndex:[quoteText rangeOfString:qbidIdentifier].location+6] substringToIndex:[[quoteText substringFromIndex:[quoteText rangeOfString:qbidIdentifier].location+6] rangeOfString:messageIdentifier].location];
    annotation.quotedUserQBId = authorQBId;
    
    // origin message
    NSString* message = [[quoteText substringFromIndex:[quoteText rangeOfString:messageIdentifier].location+5] substringToIndex:[[quoteText substringFromIndex:[quoteText rangeOfString:messageIdentifier].location+5] rangeOfString:quoteDelimiter].location];
    annotation.quotedMessageText = message;
}


@end
