//
//  Helper.m
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import "Helper.h"

@implementation Helper

+(BOOL)isStringCorrect:(NSString*)stringToCheck{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [stringToCheck stringByTrimmingCharactersInSet:whitespace];
    if ([trimmed length] == 0) {
        return NO;
    }
    return YES;
}

@end
