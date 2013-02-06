//
//  ChatControllerDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>

@protocol ChatControllerDelegate <NSObject>

@optional
-(void)willUpdate;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation addToTop:(BOOL)toTop isFBCheckin:(BOOL)isFBCheckin;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable isFBCheckin:(BOOL)isFBCheckin;
@end
