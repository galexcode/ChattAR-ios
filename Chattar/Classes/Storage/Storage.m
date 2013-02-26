//
//  Storage.m
//  Chattar
//
//  Created by kirill on 2/26/13.
//
//

#import "Storage.h"

@implementation Storage

                        // MUST reimplement this methods in subclasses
-(BOOL)isStorageEmpty{
    return NO;
}
-(void)showWorldDataFromStorage{
    
}
-(void)showFriendsDataFromStorage{
    
}

-(void)refreshDataFromStorage{
    
}
-(void)addDataToStorage:(UserAnnotation*)newData{
    
}
-(void)removeLastObjectFromStorage{
    
}
-(void)clearStorage{
    
}
-(BOOL)storageContainsObject:(UserAnnotation*)object{
    return NO;
}
-(UserAnnotation*)retrieveDataFromStorageWithIndex:(NSInteger)index{
    return nil;
}

-(NSInteger)storageCount{
    return 0;
}
-(NSInteger)allDataCount{
    return 0;
}

-(void)insertObjectToAllData:(UserAnnotation*)object atIndex:(NSInteger)index{
    
}
-(void)insertObjectToPartialData:(UserAnnotation*)object atIndex:(NSInteger)index{
    
}
-(void)removeAllPartialData{
    
}

@end
