//
//  CustomTabBarController.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <UIKit/UIKit.h>
#import "BackgroundWorker.h"
@interface CustomTabBarController : UITabBarController<FBDataDelegate,QBDataDelegate,DataDelegate,ChatControllerDelegate,
                                    MapControllerDelegate,ARControllerDelegate>
@end
