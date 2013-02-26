//
//  Storage.h
//  Chattar
//
//  Created by kirill on 2/26/13.
//
//

#import <Foundation/Foundation.h>
#import "UserAnnotation.h"

@interface Storage : NSObject

-(BOOL)isStorageEmpty;
-(void)showWorldDataFromStorage;
-(void)showFriendsDataFromStorage;

-(void)refreshDataFromStorage;
-(void)addDataToStorage:(UserAnnotation*)newData;
-(void)removeLastObjectFromStorage;
-(void)clearStorage;
-(BOOL)storageContainsObject:(UserAnnotation*)object;
-(UserAnnotation*)retrieveDataFromStorageWithIndex:(NSInteger)index;

-(NSInteger)storageCount;
-(NSInteger)allDataCount;

-(void)insertObjectToAllData:(UserAnnotation*)object atIndex:(NSInteger)index;
-(void)insertObjectToPartialData:(UserAnnotation*)object atIndex:(NSInteger)index;
-(void)removeAllPartialData;
@end
