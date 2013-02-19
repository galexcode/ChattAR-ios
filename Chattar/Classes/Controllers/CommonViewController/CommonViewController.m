//
//  CommonViewController.m
//  Chattar
//
//  Created by kirill on 2/19/13.
//
//

#import "CommonViewController.h"

@interface CommonViewController ()

@end

@implementation CommonViewController
@synthesize allFriendsSwitch;
@synthesize loadingIndicator = _loadingIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        showAllUsers = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    allFriendsSwitch = [CustomSwitch customSwitch];
    [allFriendsSwitch setAutoresizingMask:(UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin)];
    
    if(IS_HEIGHT_GTE_568){
        [allFriendsSwitch setCenter:CGPointMake(280, 448)];
    }else{
        [allFriendsSwitch setCenter:CGPointMake(280, 360)];
    }
    
    [allFriendsSwitch setValue:worldValue];
    [allFriendsSwitch scaleSwitch:0.9];
    [allFriendsSwitch addTarget:self action:@selector(allFriendsSwitchValueDidChanged:) forControlEvents:UIControlEventValueChanged];
	[allFriendsSwitch setBackgroundColor:[UIColor clearColor]];
	[self.view addSubview:allFriendsSwitch];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([DataManager shared].isFirstStartApp) {
        [self addSpinner];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addSpinner{
    if (!_loadingIndicator) {
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    if (![self.view viewWithTag:INDICATOR_TAG]) {
        [self.view addSubview:_loadingIndicator];
        [_loadingIndicator startAnimating];
    }
    
    _loadingIndicator.center = self.view.center;
    [self.view bringSubviewToFront:_loadingIndicator];
    
    [_loadingIndicator setTag:INDICATOR_TAG];
}


- (void)allFriendsSwitchValueDidChanged:(id)sender{
    float origValue = [(CustomSwitch *)sender value];
    int stateValue;
    if(origValue >= worldValue){
        stateValue = 1;
    }else if(origValue <= friendsValue){
        stateValue = 0;
    }
    
    switch (stateValue) {
            // show Friends
        case 0:{
            if(!showAllUsers){
                [self showFriends];
                showAllUsers = YES;
            }
        }
            break;
            
            // show World
        case 1:{
            if(showAllUsers){
                [self showWorld];
                showAllUsers = NO;
            }
        }
            break;
    }
}

-(void)showWorld{
    // subclassses should override this method
}

-(void)showFriends{
    // subclassses should override this method
}


@end
