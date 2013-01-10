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

@protocol PhotoMarkerProtocol <NSObject>

@required
-(void)touchOn:(UITapGestureRecognizer*)recognizer;

@end

@interface PhotoMarkerView : MKAnnotationView{
    AsyncImageView* fullPhoto;
    AsyncImageView* thumbnailPhoto;
    
    id<PhotoMarkerProtocol> delegate;
}
@end
