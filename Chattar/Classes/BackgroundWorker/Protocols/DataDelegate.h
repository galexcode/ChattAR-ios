//
//  DataDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import "ChatViewController.h"
#import "MapViewController.h"

@protocol DataDelegate <NSObject>

@optional
-(void)didReceiveError;
-(void)endRetrievingData;

@end
