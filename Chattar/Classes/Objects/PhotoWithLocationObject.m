//
//  PhotoWithLocationObject.m
//  Chattar
//
//  Created by kirill on 12/28/12.
//
//

#import "PhotoWithLocationObject.h"

@implementation PhotoWithLocationObject
@synthesize fullPhoto;
@synthesize photoLocation;
@synthesize photoThumbNail;
@synthesize locationName;
@synthesize locationID;

-(void)dealloc{
    [locationName release];
    [fullPhoto release];
    [photoThumbNail release];
    [super dealloc];
}
@end
