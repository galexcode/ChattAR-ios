//
//  PhotoMarkerView.h
//  Chattar
//
//  Created by kirill on 1/9/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import "UserAnnotation.h"
#import "MapMarkerView.h"

@interface PhotoMarkerView : MapMarkerView<UIGestureRecognizerDelegate>{
    AsyncImageView* fullPhoto;
    AsyncImageView* thumbnailPhoto;
}


@end
