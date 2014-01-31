//
//  DialogsCell.m
//  ChattAR
//
//  Created by Igor Alefirenko on 29/10/2013.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "DialogsCell.h"

@implementation DialogsCell

+ (void)configureDialogsCell:(DialogsCell *)cell forIndexPath:(NSIndexPath *)indexPath forUser:(NSDictionary *)user
{
    // cancel previous user's avatar loading
    [[AsyncImageLoader sharedLoader] cancelLoadingImagesForTarget:cell.asyncView];
    [cell.asyncView setImage:[UIImage imageNamed:@"human.png"]];
    
    // load user's avatar
    [cell.asyncView setImageURL:[NSURL URLWithString:[user objectForKey:kPhoto]]];
    
    // set user's text
    cell.name.text = [user objectForKey:kName];
    
    if ([user[kUnread] boolValue]) {
        cell.backgroundColor = [UIColor colorWithRed:62/255.0 green:136/255.0 blue:203/255.0 alpha:0.09];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}
// 14,97,147
// 62,136,203
@end
