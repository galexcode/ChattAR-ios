//
//  ChatControllerDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import "ChatViewController.h"
#import "UserAnnotation.h"

@protocol ChatControllerDelegate <NSObject>

@optional
-(void)willUpdate;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable isFBCheckin:(BOOL)isFBCheckin;
@end
