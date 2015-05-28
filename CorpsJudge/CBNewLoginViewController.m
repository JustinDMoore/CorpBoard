//
//  CBNewLoginViewController.m
//  CorpBoard
//
//  Created by Justin Moore on 11/20/14.
//  Copyright (c) 2014 Justin Moore. All rights reserved.
//

#import "CBNewLoginViewController.h"
#import <Parse/Parse.h>
//#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "ParseErrors.h"
#import "KVNProgress.h"
#import "Configuration.h"
#import "IQKeyboardManager.h"

@interface CBNewLoginViewController () {
    //NSTimer *timerCountdown;
    CBSingle *data;
    CBNewsSingleton *news;
   
}

@property (nonatomic, strong) NSMutableArray *arrayOfSubviews;
@property (nonatomic, strong) CBIsNewUser *viewIsNewUser;
@property (nonatomic, strong) CBViewSignIn *viewSignIn;
@property (nonatomic, strong) CBEmailLogin *viewEmailLogin;
@property (nonatomic, strong) CBEmailLogin *viewNewUser;
@property (nonatomic, strong) CBNicknameView *viewNickname;
@property (nonatomic, strong) CBProgressView *viewProgress;

@property (nonatomic) BOOL isNewUser;

@property (nonatomic) BOOL theBool;
//@property (nonatomic, strong) NSTimer *myTimer;
@property (nonatomic, strong) PFUser *currentUser;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollLogin;

@end

@implementation CBNewLoginViewController

-(void)viewDidAppear:(BOOL)animated {
    
    
    // *****************************************************
    
    // THE FOLLOWING LINE WILL CREATE ALL SHOWS AND SCORES
    
    //Configuration *config = [[Configuration alloc] init];
    //[config getAllCorps]; //automatically calls createAllShows
    // ****************************************************
    
    //[[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
    
    if ([PFUser currentUser]) {
        [self addView:self.viewProgress andScroll:NO];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"messages"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if ([objects count]) {
                PFObject *obj = [objects lastObject];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:obj[@"message"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                BOOL useApp = [obj[@"canUseApp"] boolValue];
                if (useApp) {
                    [self checkForPush];
                }
            } else {
                [self checkForPush];
            }
        } else {
            [self.viewProgress errorProgress:[ParseErrors getErrorStringForCode:error.code]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[ParseErrors getErrorStringForCode:error.code] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

-(void)checkForPush {

    //check to see if push notifications are enabled
    BOOL pushAllowed = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    if (!pushAllowed) {
        
        PFInstallation *install = [PFInstallation currentInstallation];
        BOOL parsePushAllowed = [install[@"allowsPush"] boolValue];
        if (parsePushAllowed) {
            
            CBPushNotifications *viewPush = [[[NSBundle mainBundle] loadNibNamed:@"CBPushNotifications"
                                                                           owner:self
                                                                         options:nil]
                                             objectAtIndex:0];
            viewPush.parentNav = self.view;
            [viewPush show];
            [viewPush setDelegate:self];
        } else {
            [self continueLoading];
        }
        
    } else {
        [self continueLoading];
        [data setParsePush:YES];
    }
}

-(void)continueLoading {
    
    self.currentUser = [PFUser currentUser];
    if (self.currentUser) {
        
        if([CLLocationManager locationServicesEnabled]){
            
            switch ([CLLocationManager authorizationStatus]) {
                case kCLAuthorizationStatusDenied:
                    break;
                case kCLAuthorizationStatusNotDetermined:
                    break;
                case kCLAuthorizationStatusAuthorizedAlways:
                     [data updateUserLocationAndLastLogin];
                    break;
                case kCLAuthorizationStatusAuthorizedWhenInUse:
                     [data updateUserLocationAndLastLogin];
                    break;
                case kCLAuthorizationStatusRestricted:
                    break;
            }
        }

        [self.currentUser fetchInBackgroundWithTarget:self selector:@selector(callbackWithResult:error:)];
    } else {
        // NEW USER, SHOW THE NEW USER DIALOG
        NSLog(@"New user.");
        [self addView:self.viewIsNewUser andScroll:NO];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CBAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.alertParentView = self.navigationController.view;
    
    data = [CBSingle data];
    news = [CBNewsSingleton news];
    [data setDelegate:self];
    [news setDelegate:self];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;
    self.scrollLogin.delegate = self;
    [self getFactCount];
    [PFCloud callFunctionInBackground:@"registerActivity" withParameters:@{}];
}

-(void)callbackWithResult:(PFObject *)refreshedObject error:(NSError *)error {
    
    //set admin
    BOOL admin = [self.currentUser[@"isAdmin"] boolValue];
    
    NSMutableArray *arrayOfChannels = [[NSMutableArray alloc] init];
    [arrayOfChannels addObject:@"global"];
    if (admin) [arrayOfChannels addObject:@"admin"];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.channels = arrayOfChannels;
    [currentInstallation saveInBackground];
    
    NSString *name = self.currentUser[@"nickname"];
    if ([name length]) {
        [self loadData];
    } else {
        [self addView:self.viewNickname andScroll:NO];
    }
}

-(BOOL)adminChannelSubscribed {
    
    NSArray *subscribedChannels = [PFInstallation currentInstallation].channels;
    for (NSString *channel in subscribedChannels) {
        if ([channel isEqualToString:@"admin"]) {
            return YES;
        }
    }
    return NO;
}

-(void)useApp {
    [self performSegueWithIdentifier:@"menu" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark
#pragma mark - Loading Data
#pragma mark

-(void)loadData {
    
    //[self getFactCount];
    [self addView:self.viewProgress andScroll:NO];
    [self.viewProgress startProgress];
    [data refreshAdmin];
    [data refreshCorpsAndShows];
}

-(void)getFactCount {
    
    [PFCloud callFunctionInBackground:@"getRandomFact"
                       withParameters:@{}
                                block:^(NSArray *factArray, NSError *error) {
                                    if (!error) {
                                        if (factArray) {
                                            PFObject *fact = [factArray lastObject];
                                            if (fact) {
                                                [self.viewProgress setFact:fact[@"fact"]];
                                            }
                                        }
                                        
                                    } else {
                                        NSLog(@"Could not call cloud function for fact.");
                                    }
                                }];
    
}

#pragma mark
#pragma mark - UIScrollView Delegates
#pragma mark
bool removeNewUserView = NO;
bool removeSignInView = NO;
bool removeEmailView = NO;
bool removeNewUserEmail = NO;
bool removeProgressView = NO;
-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (removeNewUserView) {
        [self removeViewFromScrollView:self.viewIsNewUser];
        removeNewUserView = NO;
    }
    
    if (removeSignInView) {
        [self removeViewFromScrollView:self.viewSignIn];
        removeSignInView = NO;
    }
    
    if (removeEmailView) {
        [self removeViewFromScrollView:self.viewEmailLogin];
        removeEmailView = NO;
    }
    if (removeNewUserEmail) {
        [self removeViewFromScrollView:self.viewNewUser];
        removeNewUserEmail = NO;
    }
    if (removeProgressView) {
        [self removeViewFromScrollView:self.viewProgress];
        removeProgressView = NO;
    }
}

#pragma mark
#pragma mark - Protocol Methods
#pragma mark

//Progress
-(void)progressComplete {
    self.viewProgress = nil;
    [self performSelector:@selector(useApp) withObject:nil afterDelay:0];
}

//CBIsNewUser.h
-(void)isNewUser:(BOOL)newUser {
    self.isNewUser = newUser;
    [self addView:self.viewSignIn andScroll:YES];
    
    if (!newUser) [self.viewSignIn setTitleMessage:@"SIGN IN USING"];
    else [self.viewSignIn setTitleMessage:@"SIGN UP USING"];
}

//SIGN IN/SIGN UP
-(void)SignInCancelled {
    removeSignInView = YES;
    [self.scrollLogin scrollRectToVisible:self.viewIsNewUser.frame animated:YES];
    
}

-(void)loginSuccessful:(BOOL)needsNickName {
    
    if (!needsNickName) {
        [self loadData];
    } else {
        [self addView:self.viewNickname andScroll:YES];
    }
}

-(void)emailSelected {
    self.navigationController.view.backgroundColor = [UIColor blackColor];
    if (self.isNewUser) {
        self.viewNewUser.alpha = 0;
        [self.navigationController.view addSubview:self.viewNewUser];
        [self.viewNewUser showInParent:self.view];
        self.viewNewUser.isNewUser = self.isNewUser;
    } else {
        self.viewEmailLogin.alpha = 0;
        [self.navigationController.view addSubview:self.viewEmailLogin];
        [self.viewEmailLogin showInParent:self.view];
        self.viewEmailLogin.isNewUser = self.isNewUser;
    }
}

-(void)emailCancelled {
    
    if (self.isNewUser) {
        removeNewUserEmail = YES;
    } else {
        
        removeEmailView = YES;
    }
    
    [self.scrollLogin scrollRectToVisible:self.viewSignIn.frame animated:YES];
}

-(void)loggingIn {

    //by calling start progess here, it is being called twice
    //which results in an infinite loop
    //[self addView:self.viewProgress andScroll:YES];
    //[self.viewProgress startProgress];
}

-(void)errorLoggingIn {
    removeProgressView = YES;
    UIView *previousView = [self.arrayOfSubviews objectAtIndex:[self.arrayOfSubviews count] - 2];
    [self.scrollLogin scrollRectToVisible:previousView.frame animated:YES];
}

-(void)successfulLoginFromEmail {
    [self loadData];
}

-(void)nicknameChosen {
    [self loadData];
}

-(void)newUserCreatedFromEmail {
    [self addView:self.viewNickname andScroll:YES];
}

-(void)addView:(UIView *)viewToAdd andScroll:(BOOL)scroll {
    
    viewToAdd.frame = CGRectMake(viewToAdd.frame.origin.x, 0, self.scrollLogin.frame.size.width, self.scrollLogin.frame.size.height);
    
    
    if ([self.arrayOfSubviews count]) {
        UIView *view = [self.arrayOfSubviews lastObject];
        viewToAdd.frame = CGRectMake(view.frame.origin.x + view.frame.size.width, 0, self.scrollLogin.frame.size.width, self.scrollLogin.frame.size.height);
        self.scrollLogin.contentSize = CGSizeMake(self.scrollLogin.contentSize.width + self.scrollLogin.frame.size.width, self.scrollLogin.frame.size.height);
    } else {
        viewToAdd.frame = CGRectMake(self.scrollLogin.frame.size.width, 0, self.scrollLogin.frame.size.width, self.scrollLogin.frame.size.height);
        self.scrollLogin.contentSize = CGSizeMake(self.scrollLogin.frame.size.width * 2, self.scrollLogin.frame.size.height);
    }

    [self.scrollLogin addSubview:viewToAdd];
    [self.scrollLogin scrollRectToVisible:viewToAdd.frame animated:scroll];
    
    
    [self.arrayOfSubviews addObject:viewToAdd];

}

-(void)removeViewFromScrollView:(UIView *)viewToRemove {
    
    self.scrollLogin.contentSize = CGSizeMake(self.scrollLogin.contentSize.width - viewToRemove.frame.size.width, self.scrollLogin.contentSize.height);
    for (UIView *view in self.arrayOfSubviews) {
        if (view == viewToRemove) {
            [self.arrayOfSubviews removeObject:view];
        }
    }
    [viewToRemove removeFromSuperview];
}

#pragma mark
#pragma mark - Data callbacks
#pragma mark

-(void)dataDidBeginLoading {
    
}

-(void)dataDidLoad {
    [self checkAllProgress];
}

-(void)dataFailed {
    
    [self.viewProgress errorProgress:@"There was a problem connecting to the sever."];
    NSLog(@"data load failed");
}

-(void)newsDidLoad {
    
    [self checkAllProgress];
}

-(void)checkAllProgress {

    if (news.newsLoaded && data.dataLoaded) {
        [self.viewProgress completeProgress];
    }
}

#pragma mark
#pragma mark - Lazy inits
#pragma mark

-(NSMutableArray *)arrayOfSubviews {
    if (!_arrayOfSubviews) {
        _arrayOfSubviews = [[NSMutableArray alloc] init];
    }
    return _arrayOfSubviews;
}

-(CBNicknameView *)viewNickname {
    if (!_viewNickname) {
        _viewNickname =
        [[[NSBundle mainBundle] loadNibNamed:@"CBNickname"
                                       owner:self
                                     options:nil]
         objectAtIndex:0];
        [_viewNickname setDelegate:self];
        _viewNickname.viewToScroll = self.view;
    }
    return _viewNickname;
}

-(CBIsNewUser *)viewIsNewUser {
    if (!_viewIsNewUser) {
        _viewIsNewUser =
        [[[NSBundle mainBundle] loadNibNamed:@"CBIsNewUser"
                                       owner:self
                                     options:nil]
         objectAtIndex:0];
        _viewIsNewUser.parent = self;
        [_viewIsNewUser setDelegate:self];
    }
    return _viewIsNewUser;
}

-(CBViewSignIn *)viewSignIn {
    if (!_viewSignIn) {
        _viewSignIn =
        [[[NSBundle mainBundle] loadNibNamed:@"CBViewSignIn"
                                       owner:self
                                     options:nil]
         objectAtIndex:0];
        [_viewSignIn setDelegate:self];
    }
    return _viewSignIn;
}

-(CBEmailLogin *)viewEmailLogin {
    if (!_viewEmailLogin) {
        self.viewEmailLogin =
        [[[NSBundle mainBundle] loadNibNamed:@"CBExistingUser"
                                       owner:self
                                     options:nil]
         objectAtIndex:0];
        [_viewEmailLogin setDelegate:self];
    }
    return _viewEmailLogin;
}

-(CBProgressView *)viewProgress {
    if (!_viewProgress) {
        _viewProgress =
        [[[NSBundle mainBundle] loadNibNamed:@"CBProgressView"
                                       owner:self
                                     options:nil]
         objectAtIndex:0];
        [_viewProgress setDelegate:self];
    }
    return _viewProgress;
}

-(CBEmailLogin *)viewNewUser {
    if (!_viewNewUser) {
            _viewNewUser = [[[NSBundle mainBundle] loadNibNamed:@"CBNewUser"
                                       owner:self
                                     options:nil]
         objectAtIndex:0];
        [_viewNewUser setDelegate:self];
    }
    return _viewNewUser;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.viewProgress = nil;
}

#pragma mark
#pragma mark - Push Notification Protocol
#pragma mark

-(void)allowPush {
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];

    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [self continueLoading];
    
    BOOL pushAllowed = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    [data setParsePush:pushAllowed];
}

-(void)denyPush {
    
    [data setParsePush:NO];
    [self continueLoading];
}

@end
