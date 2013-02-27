//
//  ChatPointsStorage.h
//  Chattar
//
//  Created by kirill on 2/26/13.
//
//

#import <Foundation/Foundation.h>
#import "Storage.h"
#import "BackgroundWorker.h"

@interface ChatPointsStorage : Storage
@property (nonatomic, retain) QBLGeoData* geoData;
@end
