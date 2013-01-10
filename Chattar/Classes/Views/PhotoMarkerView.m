//
//  PhotoMarkerView.m
//  Chattar
//
//  Created by kirill on 1/9/13.
//
//

#import "PhotoMarkerView.h"

@implementation PhotoMarkerView

-(id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        if ([annotation isKindOfClass:[UserAnnotation class]]) {
            UserAnnotation* ann = (UserAnnotation*)annotation;
            thumbnailPhoto = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 70)];
            fullPhoto = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 0, 120, 160)];
            [fullPhoto loadImageFromURL:[NSURL URLWithString:ann.fullImageURL]];
            [thumbnailPhoto loadImageFromURL:[NSURL URLWithString:ann.thumbnailURL]];

            [self addSubview:thumbnailPhoto];
            [self bringSubviewToFront:thumbnailPhoto];
            
            UIImageView *arrow = [[UIImageView alloc] init];
            [arrow setImage:[UIImage imageNamed:@"radarMarkerArrow@2x.png"]];
            [arrow setFrame:CGRectMake(thumbnailPhoto.frame.size.width/2-5, thumbnailPhoto.frame.size.height-2, 10, 9)];
            [self addSubview: arrow];
            [arrow release];
            
            [self setUserInteractionEnabled:YES];
            
            UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchOn:)];
            [self addGestureRecognizer:tap];
            [tap release];
        }
    }
    return self;
}

-(void)touchOn:(UIGestureRecognizer*)recognizer{
    
}

-(void)dealloc{
    [thumbnailPhoto release];
    [fullPhoto release];
    [super dealloc];
}

@end
