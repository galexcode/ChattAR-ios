//
//  PhotoMarkerView.m
//  Chattar
//
//  Created by kirill on 1/9/13.
//
//

#import "PhotoMarkerView.h"

@implementation PhotoMarkerView
@synthesize delegate;

-(id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        if ([annotation isKindOfClass:[UserAnnotation class]]) {
            UserAnnotation* ann = (UserAnnotation*)annotation;
            [self setFrame:CGRectMake(0, 0, 120, 70)];
            thumbnailPhoto = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 70)];
            fullPhoto = [[AsyncImageView alloc] initWithFrame:CGRectMake(20, 20, 250, 300)];
            [thumbnailPhoto loadImageFromURL:[NSURL URLWithString:ann.thumbnailURL]];
            
            [fullPhoto setLinkedUrl:[NSURL URLWithString:ann.thumbnailURL]];
            [self addSubview:thumbnailPhoto];
            [self bringSubviewToFront:thumbnailPhoto];
            
            UIImageView *arrow = [[UIImageView alloc] init];
            [arrow setImage:[UIImage imageNamed:@"radarMarkerArrow@2x.png"]];
            [arrow setFrame:CGRectMake(thumbnailPhoto.frame.size.width/2-5, thumbnailPhoto.frame.size.height-2, 10, 9)];
            [self addSubview: arrow];
            [arrow release];
            
            [self setUserInteractionEnabled:YES];
            [thumbnailPhoto setUserInteractionEnabled:YES];
            [self setCanShowCallout:NO];

            UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchOn:)];
                        
            [self addGestureRecognizer:tap];
            [tap setDelegate:self];
            [tap release];
            
            
        }
    }
    return self;
}



-(void)touchOn:(UITapGestureRecognizer*)recognizer{
    // create full screen view
    UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setFrame:CGRectMake(fullPhoto.frame.size.width-20, -10, 29, 29)];
    NSLog(@"%@",[UIImage imageNamed:@"close.png"]);
    [closeButton setImage:[UIImage imageNamed:@"FBDialog.bundle/images/close.png"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    [fullPhoto addSubview:closeButton];
    if ([delegate respondsToSelector:@selector(makeFullScreenView:)]) {
                // "lazy" image load
        [fullPhoto loadImageFromURL:fullPhoto.linkedUrl];
        [delegate makeFullScreenView:fullPhoto];
    }
}

#pragma mark -
#pragma mark UIGestureRecognizer delegate methods
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

-(void)closeView{
    [fullPhoto removeFromSuperview];
}


-(void)dealloc{
    [thumbnailPhoto release];
    [fullPhoto release];
    [super dealloc];
}

@end
