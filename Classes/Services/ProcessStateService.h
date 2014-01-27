//
//  ProcessStateService.h
//  ChattAR
//
//  Created by Igor Alefirenko on 27/01/2014.
//  Copyright (c) 2014 Stefano Antonelli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProcessStateService : NSObject

// loading chat rooms status
@property (nonatomic, assign) BOOL chatTrengingRoomsLoaded;
@property (nonatomic, assign) BOOL chatLocalRoomsLoaded;
// loading facebook users status
@property (nonatomic, assign) BOOL facebookUsersLoaded;
// loading facebook friends status
@property (nonatomic, assign) BOOL facebookFriendsLoaded;

+ (instancetype)shared;
- (BOOL)splashCanBeDismissed;

@end
