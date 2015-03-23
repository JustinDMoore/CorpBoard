//
//  CBUserProfileViewController.m
//  CorpBoard
//
//  Created by Isaias Favela on 12/10/14.
//  Copyright (c) 2014 Justin Moore. All rights reserved.
//

#import "CBUserProfileViewController.h"
#import "NSDate+Utilities.h"
#import "CBSingle.h"
#import "KVNProgress.h"

#import "AppConstant.h"
#import "messages.h"
#import "ChatView.h"
#import "IQKeyboardManager.h"
#import "Configuration.h"

@interface CBUserProfileViewController () {
    CBSingle *_data;
    BOOL profileLoaded;
}

@property (nonatomic, strong) NSMutableArray *arrayOfCorpExperience;
@property (nonatomic, strong) NSMutableArray *arrayOfCorpExperienceLabels;
@property (nonatomic, strong) UILabel *lblBackground;

@property (nonatomic, strong) UIBarButtonItem *btnEditProfile;

// EDIT BUTTONS
@property (weak, nonatomic) IBOutlet UIButton *btnEditPicture;
@property (weak, nonatomic) IBOutlet UIButton *btnEditName;
@property (weak, nonatomic) IBOutlet UIButton *btnEditBadges;
@property (weak, nonatomic) IBOutlet UIButton *btnEditCorpExperience;
@property (weak, nonatomic) IBOutlet UIButton *btnEditDescription;

@property (nonatomic, strong) CBEditName *viewEditName;
@property (nonatomic, strong) CBUserCategories *userCat;
@property (nonatomic, strong) CBChooseCorp *corpExperience;
@property (nonatomic, strong) CBEditDescription *viewEditDescription;
@property (nonatomic, strong) CBCorpExperienceList *viewExperienceList;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollProfile;
@property (weak, nonatomic) IBOutlet UIView *viewProfile;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollCoverPhoto;
@property (weak, nonatomic) IBOutlet PFImageView *imgCoverPhoto;
@property (nonatomic, strong) NSMutableArray *arrayOfBadges;
@property (nonatomic, strong) NSMutableArray *arrayOfSectionLabels;

//UI
@property (weak, nonatomic) IBOutlet PFImageView *imgUser;
@property (weak, nonatomic) IBOutlet UILabel *lblUserNickname;
@property (weak, nonatomic) IBOutlet UILabel *lblUserLocation;
@property (weak, nonatomic) IBOutlet UILabel *lblViews;
@property (weak, nonatomic) IBOutlet UIView *viewControls;
@property (weak, nonatomic) IBOutlet UILabel *lblAboutMe;
@property (weak, nonatomic) IBOutlet UILabel *lblMyBadges;
@property (strong, nonatomic) UILabel *lblCorpExperience;
@property (strong, nonatomic) UILabel *lblUserBackground;
@property (weak, nonatomic) IBOutlet UIButton *btnReport;
@property (weak, nonatomic) IBOutlet UIButton *btnChat;

- (IBAction)btnChat_clicked:(id)sender;
- (IBAction)btnReport_clicked:(id)sender;

@end

@implementation CBUserProfileViewController

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [self.navigationItem setHidesBackButton:NO animated:NO];
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backBtnImage = [UIImage imageNamed:@"arrowLeft"];
    [backBtn setBackgroundImage:backBtnImage forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    backBtn.frame = CGRectMake(0, 0, 30, 30);
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn] ;
    self.navigationItem.leftBarButtonItem = backButton;
    self.title = @"Profile";
    
    PFUser *cUser = [PFUser currentUser];
    if ([self.userProfile.objectId isEqualToString: cUser.objectId]) {
        UIButton *configBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *configBtnImage = [UIImage imageNamed:@"Config"];
        [configBtn setBackgroundImage:configBtnImage forState:UIControlStateNormal];
        [configBtn addTarget:self action:@selector(configProfile) forControlEvents:UIControlEventTouchUpInside];
        configBtn.frame = CGRectMake(0, 0, 30, 30);
        self.btnEditProfile = [[UIBarButtonItem alloc] initWithCustomView:configBtn] ;
        self.navigationItem.rightBarButtonItem = self.btnEditProfile;
        if (profileLoaded) {
            self.btnEditProfile.enabled = YES;
        } else {
            self.btnEditProfile.enabled = NO;
        }
        self.btnReport.enabled = NO;
        self.btnChat.enabled = NO;
    } else {
        self.btnReport.enabled = YES;
        self.btnChat.enabled = YES;
        NSMutableDictionary * params = [NSMutableDictionary new];
        params[@"userObjectId"] = self.userProfile.objectId;
        [PFCloud callFunctionInBackground:@"incrementUserProfileViews" withParameters:params];
    }
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:NO];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_main_queue(), ^{
        [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
        [KVNProgress show];
    });
    
    
    _data = [CBSingle data];
    self.imgUser.layer.cornerRadius = self.imgUser.frame.size.width/2;
    self.imgUser.layer.masksToBounds = YES;
    
    editingProfile = NO;
    
    [self getUserCorpExperiences];
    [self setParallex];
    
    self.imgCoverPhoto.image = nil;
    self.imgUser.image = nil;
    self.lblUserNickname.text = @"";
    self.lblUserLocation.text = @"";
    self.scrollCoverPhoto.hidden = YES;
    self.scrollProfile.hidden = YES;
}

-(void)getUserCorpExperiences {
    
    [self.arrayOfCorpExperience removeAllObjects];
    PFQuery *query = [PFQuery queryWithClassName:@"userCorpExperience"];
    [query whereKey:@"user" equalTo:self.userProfile];
    [query orderByDescending:@"year"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count]) {
            [self.arrayOfCorpExperience addObjectsFromArray:objects];
            [self.viewExperienceList.tableExperience reloadData];
        }
        [self initUI];
    }];
}

-(void)setParallex {
    // Set vertical effect
    UIInterpolatingMotionEffect *verticalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.y"
     type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-20);
    verticalMotionEffect.maximumRelativeValue = @(20);
    
    // Set horizontal effect
    UIInterpolatingMotionEffect *horizontalMotionEffect =
    [[UIInterpolatingMotionEffect alloc]
     initWithKeyPath:@"center.x"
     type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-20);
    horizontalMotionEffect.maximumRelativeValue = @(20);
    
    // Create group to combine both
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    // Add both effects to your view
    [self.scrollProfile addMotionEffect:group];
    [self toggleEditButtons:NO];
}

-(void)toggleEditButtons:(BOOL)show {
    
    float offScreen = self.view.frame.size.width + 15;
    float onScreen = self.view.frame.size.width - self.btnEditPicture.frame.size.width;
    
    self.btnEditPicture.frame = CGRectMake(!editingProfile ? onScreen : offScreen,
                                           self.imgUser.frame.origin.y + self.btnEditPicture.frame.size.height + 2,
                                           self.btnEditPicture.frame.size.width,
                                           self.btnEditPicture.frame.size.height);
    
    self.btnEditName.frame = CGRectMake(!editingProfile ? onScreen : offScreen,
                                        self.lblUserNickname.frame.origin.y,
                                        self.btnEditName.frame.size.width,
                                        self.btnEditName.frame.size.height);
    
    self.btnEditBadges.frame = CGRectMake(!editingProfile ? onScreen : offScreen,
                                          self.lblMyBadges.frame.origin.y,
                                          self.btnEditBadges.frame.size.width,
                                          self.btnEditBadges.frame.size.height);
    
    self.btnEditCorpExperience.frame = CGRectMake(!editingProfile ? onScreen : offScreen,
                                                  self.lblCorpExperience.frame.origin.y,
                                                  self.btnEditCorpExperience.frame.size.width,
                                                  self.btnEditCorpExperience.frame.size.height);
    
    self.btnEditDescription.frame = CGRectMake(!editingProfile ? onScreen : offScreen,
                                               self.lblUserBackground.frame.origin.y,
                                               self.btnEditDescription.frame.size.width,
                                               self.btnEditDescription.frame.size.height);
    
    
    [UIView animateWithDuration:.2 delay:0 usingSpringWithDamping:.6 initialSpringVelocity:10 options:0 animations:^{
        
        
        self.btnEditPicture.frame = CGRectMake(editingProfile ? onScreen : offScreen,
                                               self.imgUser.frame.origin.y + self.btnEditPicture.frame.size.height + 2,
                                               self.btnEditPicture.frame.size.width,
                                               self.btnEditPicture.frame.size.height);
        
        self.btnEditName.frame = CGRectMake(editingProfile ? onScreen : offScreen,
                                            self.lblUserNickname.frame.origin.y,
                                            self.btnEditName.frame.size.width,
                                            self.btnEditName.frame.size.height);
        
        self.btnEditBadges.frame = CGRectMake(editingProfile ? onScreen : offScreen,
                                              self.lblMyBadges.frame.origin.y,
                                              self.btnEditBadges.frame.size.width,
                                              self.btnEditBadges.frame.size.height);
        
        self.btnEditCorpExperience.frame = CGRectMake(editingProfile ? onScreen : offScreen,
                                                      self.lblCorpExperience.frame.origin.y,
                                                      self.btnEditCorpExperience.frame.size.width,
                                                      self.btnEditCorpExperience.frame.size.height);
        self.btnEditDescription.frame = CGRectMake(editingProfile ? onScreen : offScreen,
                                                   self.lblUserBackground.frame.origin.y,
                                                   self.btnEditDescription.frame.size.width,
                                                   self.btnEditDescription.frame.size.height);
        
    } completion:^(BOOL finished) {
        
        
        
    }];
}

-(void)initUI {
    
    self.scrollProfile.hidden = YES;
    self.scrollCoverPhoto.hidden = YES;
    
    [self.userProfile fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        PFFile *imgFile = self.userProfile[@"picture"];
        if (imgFile) {
            [self.imgUser setFile:imgFile];
            [self.imgUser loadInBackground];
        } else {
            [self.imgUser setImage:[UIImage imageNamed:@"defaultProfilePicture"]];
        }
        
        PFFile *coverFile = self.userProfile[@"coverImage"];
        PFObject *coverPointer = self.userProfile[@"coverPointer"];
        if (coverFile) {
            [self.imgCoverPhoto setFile:coverFile];
            [self.imgCoverPhoto loadInBackground];
        } else {
            if (coverPointer) {
                [coverPointer fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    PFFile *coverFile = coverPointer[@"photo"];
                    [self.imgCoverPhoto setFile:coverFile];
                    [self.imgCoverPhoto loadInBackground];
                }];
            } else {
                [self.imgCoverPhoto setImage:[UIImage imageNamed:@"defaultCoverPicture"]];
            }
        }
        
        self.lblUserNickname.text = self.userProfile[@"nickname"];
        if ([self.userProfile[@"location"] length]) {
            self.lblUserLocation.hidden = NO;
            self.lblUserLocation.text = [NSString stringWithFormat:@"Lives in %@", self.userProfile[@"location"]];
        } else {
            self.lblUserLocation.hidden = YES;
        }
        
        // joined date
        NSString *dd = [self.userProfile.createdAt stringWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
        
        // profile views
        NSString *views;
        int profileViews = [self.userProfile[@"profileViews"] intValue];
        if (profileViews == 1) {
            views = @"1 View";
        } else {
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInt:profileViews]];
            
            views = [NSString stringWithFormat:@"%@ Views", formatted];
        }
        
        //show reviews
        NSString *reviews;
        int showReviews = [self.userProfile[@"showReviews"] intValue];
        if (showReviews == 1) {
            reviews = @"1 Show Review";
        } else {
            NSNumberFormatter *formatter = [NSNumberFormatter new];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInt:showReviews]];
            reviews = [NSString stringWithFormat:@"%@ Show Reviews", formatted];
        }
        
        self.lblViews.text = [NSString stringWithFormat:@"Joined %@  |  %@  |  %@", dd, views, reviews];
        
        //clear the current badges
        for (UILabel *badge in self.arrayOfBadges) {
            [badge removeFromSuperview];
        }
        [self.arrayOfBadges removeAllObjects];
        
        //clear the current section labels
        for (UILabel *lbl in self.arrayOfSectionLabels) {
            [lbl removeFromSuperview];
        }
        [self.arrayOfSectionLabels removeAllObjects];
        [self.lblBackground removeFromSuperview];
        self.lblBackground = nil;
        [self.lblCorpExperience removeFromSuperview];
        self.lblCorpExperience = nil;
        [self.lblUserBackground removeFromSuperview];
        self.lblUserBackground = nil;
        [self.lblBackground removeFromSuperview];
        self.lblBackground = nil;
        
        //clear the current experiences
        
        for (UILabel *lbl in self.arrayOfCorpExperienceLabels) {
            [lbl removeFromSuperview];
        }
        [self.arrayOfCorpExperienceLabels removeAllObjects];
        
        
        //user badges
        int y = self.lblMyBadges.frame.origin.y + 30;
        
        if ([self.userProfile[@"arrayOfCategories"] count]) {
            for(int i = 0; i < [self.userProfile[@"arrayOfCategories"] count]; i++) {
                
                UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.lblMyBadges.frame.origin.x, y, 200, 50)];
                [myLabel setBackgroundColor:[UIColor clearColor]];
                [myLabel setTextColor:[UIColor lightGrayColor]];
                [[myLabel layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                [[myLabel layer] setBorderWidth:1];
                [myLabel setText:[NSString stringWithFormat:@" %@ ",[self.userProfile[@"arrayOfCategories"] objectAtIndex:i]]];
                [myLabel setFont:[UIFont systemFontOfSize:14]];
                [myLabel sizeToFit];
                [[self viewProfile] addSubview:myLabel];
                [self.arrayOfBadges addObject:myLabel];
                y+= 5 + myLabel.frame.size.height;
            }
        } else {
            UILabel *myLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.lblMyBadges.frame.origin.x, y, 200, 50)];
            [myLabel setBackgroundColor:[UIColor clearColor]];
            [myLabel setTextColor:[UIColor lightGrayColor]];
            [[myLabel layer] setBorderColor:[UIColor lightGrayColor].CGColor];
            [[myLabel layer] setBorderWidth:1];
            [myLabel setText:@" New User "];
            [myLabel setFont:[UIFont systemFontOfSize:14]];
            [myLabel sizeToFit];
            [[self viewProfile] addSubview:myLabel];
            [self.arrayOfBadges addObject:myLabel];
            y+= 5 + myLabel.frame.size.height;
        }
        
        // corp experience
        y+= 20;
        
        self.lblCorpExperience = [[UILabel alloc]initWithFrame:CGRectMake(self.lblMyBadges.frame.origin.x, y, 200, 40)];
        self.lblCorpExperience.text = @"Corp Experience";
        self.lblCorpExperience.font = self.lblMyBadges.font;
        self.lblCorpExperience.textColor = self.lblMyBadges.textColor;
        [self.lblCorpExperience sizeToFit];
        [self.lblCorpExperience sizeToFit];
        [self.viewProfile addSubview:self.lblCorpExperience];
        [self.arrayOfSectionLabels addObject:self.lblCorpExperience];
        y = self.lblCorpExperience.frame.origin.y;
        
        if ([self.arrayOfCorpExperience count]) { //we have experience
            
            for (PFObject *exp in self.arrayOfCorpExperience) {
                NSString *str = [NSString stringWithFormat:@"%@, %@ - %@", exp[@"corpsName"], exp[@"year"], exp[@"position"]];
                UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(self.lblCorpExperience.frame.origin.x, y+30, 200, 40)];
                lbl.text = str;
                lbl.backgroundColor = [UIColor clearColor];
                lbl.textColor = [UIColor lightGrayColor];
                [lbl setFont:[UIFont systemFontOfSize:12]];
                [lbl sizeToFit];
                [self.viewProfile addSubview:lbl];
                [self.arrayOfCorpExperienceLabels addObject:lbl];
                y+=5 + lbl.frame.size.height;
            }
            
        } else { //we have no experience
            y+=30;
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(self.lblCorpExperience.frame.origin.x, y, 200, 40)];
            lbl.text = @"No corp experience listed";
            lbl.backgroundColor = [UIColor clearColor];
            lbl.textColor = [UIColor lightGrayColor];
            [lbl setFont:[UIFont systemFontOfSize:12]];
            [lbl sizeToFit];
            [self.viewProfile addSubview:lbl];
            [self.arrayOfCorpExperienceLabels addObject:lbl];
        }
        
        //user background
        y+= 40;
        self.lblUserBackground = [[UILabel alloc]initWithFrame:CGRectMake(self.lblMyBadges.frame.origin.x, y, self.view.frame.size.width, 40)];
        self.lblUserBackground.text = @"Background";
        self.lblUserBackground.font = self.lblMyBadges.font;
        self.lblUserBackground.textColor = self.lblMyBadges.textColor;
        [self.lblUserBackground sizeToFit];
        [self.viewProfile addSubview:self.lblUserBackground];
        [self.arrayOfSectionLabels addObject:self.lblUserBackground];
        y = self.lblUserBackground.frame.origin.y;
        
        
        
        y+= 30;
        if ([self.userProfile[@"background"] length]) { // we have a background
            
            self.lblBackground = [[UILabel alloc] initWithFrame:CGRectMake(self.lblCorpExperience.frame.origin.x, y, self.view.frame.size.width - self.lblCorpExperience.frame.origin.x, 40)];
            self.lblBackground.text = self.userProfile[@"background"];
            self.lblBackground.backgroundColor = [UIColor clearColor];
            self.lblBackground.textColor = [UIColor lightGrayColor];
            [self.lblBackground setFont:[UIFont systemFontOfSize:12]];
            self.lblBackground.numberOfLines = 0;
            self.lblBackground.lineBreakMode = NSLineBreakByWordWrapping;
            [self.lblBackground sizeToFit];
            [self.viewProfile addSubview:self.lblBackground];
            
        } else { // we don't have a background
            
            self.lblBackground = [[UILabel alloc] initWithFrame:CGRectMake(self.lblCorpExperience.frame.origin.x, y, 200, 40)];
            self.lblBackground.text = @"No background listed";
            self.lblBackground.backgroundColor = [UIColor clearColor];
            self.lblBackground.textColor = [UIColor lightGrayColor];
            [self.lblBackground sizeToFit];
            [self.lblBackground setFont:[UIFont systemFontOfSize:12]];
            [self.lblBackground sizeToFit];
            [self.viewProfile addSubview:self.lblBackground];
            
        }
        
        //profile scrollview
        self.scrollProfile.contentSize = CGSizeMake(self.scrollProfile.frame.size.width, self.scrollProfile.frame.size.height + 200);
        [self.view bringSubviewToFront:self.scrollProfile];
        
        //cover photo scrollview
        self.imgCoverPhoto.frame = CGRectMake(self.imgCoverPhoto.frame.origin.x, self.imgCoverPhoto.frame.origin.y, self.imgCoverPhoto.frame.size.width, self.imgCoverPhoto.frame.size.height + 100);
        self.scrollCoverPhoto.contentSize = CGSizeMake(self.imgCoverPhoto.frame.size.width, self.imgCoverPhoto.frame.size.height);
        
        ht = self.scrollCoverPhoto.frame.size.height;
        
        
        //recalculate the scrollview content height
        
        self.scrollProfile.contentSize = CGSizeMake(self.scrollProfile.frame.size.width, 980 + self.lblBackground.frame.size.height);
        
        //needed to set the content offset of the cover picture
        [self scrollViewDidScroll:self.scrollProfile];
        
        editingProfile = NO;
        self.btnEditProfile.enabled = YES;
        profileLoaded = YES;
        self.scrollProfile.hidden = NO;
        self.scrollCoverPhoto.hidden = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [KVNProgress dismiss];
        });
        
    }];
}

-(void)goback {
    [self.navigationController popViewControllerAnimated:YES];
}

bool editingProfile = NO;
-(void)configProfile {
    if (editingProfile) {
        editingProfile = NO;
    } else {
        editingProfile = YES;
    }
    [self toggleEditButtons:editingProfile];
}

- (void)selectPhotos {
    
    if (coverPhoto) {
        
        [self performSegueWithIdentifier:@"coverPhotos" sender:self];
    } else {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

BOOL coverPhoto = NO;
#pragma mark
#pragma mark - UIActionsheet Delegates
#pragma mark

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            coverPhoto = YES;
            [self selectPhotos];
            break;
        case 1:
            coverPhoto = NO;
            [self selectPhotos];
            break;
        default:
            break;
    }
}

#pragma mark
#pragma mark - UIImagePickerControllerDelegate
#pragma mark

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.btnEditProfile.enabled = YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self saveProfileImage:image];
}

-(void)submitPhotoForReview:(UIImage *)photo {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
        [KVNProgress show];
    });
    
    NSData *imageData = UIImagePNGRepresentation(photo);
    //make sure the image isn't too big
    NSInteger size = imageData.length;
    if (size < 10485760) {
        
        PFFile *imageFile = [PFFile fileWithName:@"picture.png" data:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                if (succeeded) {
                    PFObject *photoForReview = [PFObject objectWithClassName:@"photos"];
                    photoForReview[@"type"] = @"Cover";
                    photoForReview[@"user"] = [PFUser currentUser];
                    photoForReview[@"isUserSubmitted"] = [NSNumber numberWithBool:YES];
                    photoForReview[@"approved"] = [NSNumber numberWithBool:NO];
                    photoForReview[@"photo"] = imageFile;
                    photoForReview[@"publicUse"] = [NSNumber numberWithBool:YES];
                    
                    [photoForReview saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
                                [KVNProgress showSuccess];
                            });
                            
                        }
                        else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                                [KVNProgress showErrorWithStatus:@"Could not upload photo"];
                            });
                        }
                    }];
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                    [KVNProgress showErrorWithStatus:@"Could not upload photo"];
                });
            }
        }];
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KVNProgress dismiss];
            [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
            [KVNProgress showErrorWithStatus:@"Image must be less than 10mb"];
        });
    }
}

-(void)saveCoverForProfile:(PFObject *)imageObject {
    
    NSData *imageData = UIImagePNGRepresentation(imageObject[@"photo"]);
    PFFile *imageFile = [PFFile fileWithName:@"picture.png" data:imageData];
    
    //make sure the image isn't too big
    NSInteger size = imageData.length;
    if (size < 10485760) {
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                
                PFObject *coverPhoto = [PFObject objectWithClassName:@"photos"];
                coverPhoto[@"type"] = @"Cover";
                coverPhoto[@"user"] = [PFUser currentUser];
                coverPhoto[@"isUserSubmitted"] = [NSNumber numberWithBool:NO];
                coverPhoto[@"approved"] = [NSNumber numberWithBool:YES];
                coverPhoto[@"photo"] = imageData;
                coverPhoto[@"publicUse"] = [NSNumber numberWithBool:YES];
                
                [coverPhoto saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        
                        self.userProfile[@"coverPointer"] = coverPhoto.objectId;
                        [self.userProfile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
                                    [KVNProgress showSuccess];
                                });
                                
                            } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                                    [KVNProgress showErrorWithStatus:@"Error"];
                                });
                            }
                        }];
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                            [KVNProgress showErrorWithStatus:@"Could not upload photo"];
                        });
                    }
                }];
            }
        }];
    } else {
        
    }
    
}

-(void)saveProfileImage:(UIImage *)photo {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
        [KVNProgress show];
    });
    
    //Have the image draw itself in the correct orientation if necessary
    if(!(photo.imageOrientation == UIImageOrientationUp ||
         photo.imageOrientation == UIImageOrientationUpMirrored))
    {
        CGSize imgsize = photo.size;
        UIGraphicsBeginImageContext(imgsize);
        [photo drawInRect:CGRectMake(0.0, 0.0, imgsize.width, imgsize.height)];
        photo = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    NSData *imageData = UIImagePNGRepresentation(photo);
    
    //NSData *imageData = UIImagePNGRepresentation(photo);
    //make sure the image isn't too big
    NSInteger size = imageData.length;
    if (size < 10485760) {
        
        PFFile *imageFile = [PFFile fileWithName:@"picture.png" data:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                
                if (succeeded) {
                    
                    PFUser *user = [PFUser currentUser];
                    user[@"picture"] = imageFile;
                    user[@"thumbnail"] = imageFile;
                    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self initUI];
                                [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
                                [KVNProgress showSuccess];
                            });
                            
                        }
                        else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                                [KVNProgress showErrorWithStatus:@"Could not update photo"];
                            });
                        }
                    }];
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                    [KVNProgress showErrorWithStatus:@"Could not update photo"];
                });
            }
        }];
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KVNProgress dismiss];
            [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
            [KVNProgress showErrorWithStatus:@"Image must be less than 10mb"];
        });
    }
}

#pragma mark
#pragma mark - IBActions
#pragma mark

- (IBAction)btnEditPicture_clicked:(id)sender {
    
    NSString *actionSheetTitle = @"Edit Profile Images"; //Action Sheet Title
    NSString *other1 = @"Cover Image";
    NSString *other2 = @"Profile Image";
    NSString *cancelTitle = @"Cancel";
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:nil
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:other1, other2, nil];
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
}


- (IBAction)btnEditName_clicked:(id)sender {
    [self.view addSubview:self.viewEditName];
    [self.viewEditName showInParent:self.view.frame];
    [self.viewEditName setDelegate:self];
}

- (IBAction)btnEditBadges_clicked:(id)sender {
    
    [self.view addSubview:self.userCat];
    [self.userCat showInParent:self.view.frame];
    [self.userCat setCategories:self.userProfile[@"arrayOfCategories"]];
    
    
    [self.userCat setDelegate:self];
    [self.userCat.tableCategories reloadData];
}

-(void)savedName {
    
    [self initUI];
    self.viewEditName = nil;
}

-(void)corpExperienceUpdated {
    
    [self getUserCorpExperiences];
    self.viewExperienceList = nil;
}

-(void)cancelledSaveName {
    
    self.viewEditName = nil;
}

UIPickerView *yearPicker;
UIPickerView *positionPicker;
UIPickerView *corpPicker;
- (IBAction)btnEditCorpExperience_clicked:(id)sender {
    
    [self.view addSubview:self.viewExperienceList];
    [self.viewExperienceList showInParent:self.view.frame];
    
    [self.viewExperienceList setDelegate:self];
    [self.viewExperienceList.tableExperience reloadData];
}

-(void)addNewCorpExperience {
    
    self.viewExperienceList.hidden = YES;
    
    [self.view addSubview:self.corpExperience];
    [self.corpExperience showInParent:self.view.frame];
    [self.view bringSubviewToFront:self.corpExperience];
    [self.corpExperience setDelegate:self];
    
    yearPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 300)];
    [yearPicker setDataSource: self];
    [yearPicker setDelegate: self];
    yearPicker.showsSelectionIndicator = YES;
    self.corpExperience.txtYear.inputView = yearPicker;
    
    positionPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 300)];
    [positionPicker setDataSource: self];
    [positionPicker setDelegate: self];
    positionPicker.showsSelectionIndicator = YES;
    self.corpExperience.txtPosition.inputView = positionPicker;
    
    corpPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 100, 300)];
    [corpPicker setDataSource: self];
    [corpPicker setDelegate: self];
    corpPicker.showsSelectionIndicator = YES;
    self.corpExperience.txtCorpsName.inputView = corpPicker;
    self.corpExperience.corpPicker = corpPicker;
    
}

- (IBAction)btnEditDescription_clicked:(id)sender {
    [self.view addSubview:self.viewEditDescription];
    [self.viewEditDescription showInParent:self.view.frame];
    
    [self.viewEditDescription setDelegate:self];
}

-(void)savedDescription {
    self.viewEditDescription = nil;
    [self initUI];
}

-(void)cancelledDescription {
    self.viewEditDescription = nil;
}

-(void)categoriesClosed {
    self.userCat = nil;
}

-(void)savedCategories {
    self.userCat = nil;
    [self initUI];
}

-(void)savedCorpExperience:(PFObject *)obj {
    [self.arrayOfCorpExperience addObject:obj];
    self.corpExperience = nil;
    if (self.viewExperienceList.hidden) {
        self.viewExperienceList.hidden = NO;
        [self.viewExperienceList showInParent:self.view.frame];
        [self.viewExperienceList.tableExperience reloadData];
    } else {
        [self getUserCorpExperiences];
    }
}

-(void)closedCorpExperience {
    self.corpExperience = nil;
}

-(void)setUser:(PFUser *)user {
    self.userProfile = user;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CBEditName *)viewEditName {
    if (!_viewEditName) {
        _viewEditName = [[[NSBundle mainBundle] loadNibNamed:@"CBEditName"
                                                       owner:self
                                                     options:nil]
                         objectAtIndex:0];
        [_viewEditName setDelegate:self];
    }
    return _viewEditName;
}

-(CBUserCategories *)userCat {
    if (!_userCat) {
        _userCat = [[[NSBundle mainBundle] loadNibNamed:@"CBUserCategories"
                                                  owner:self
                                                options:nil]
                    objectAtIndex:0];
        [_userCat setDelegate:self];
    }
    return _userCat;
}

-(CBChooseCorp *)corpExperience {
    if (!_corpExperience) {
        _corpExperience = [[[NSBundle mainBundle] loadNibNamed:@"CBChooseCorp"
                                                         owner:self
                                                       options:nil]
                           objectAtIndex:0];
        [_corpExperience setDelegate:self];
    }
    return _corpExperience;
}

-(CBEditDescription *)viewEditDescription {
    if (!_viewEditDescription) {
        _viewEditDescription = [[[NSBundle mainBundle] loadNibNamed:@"CBEditDescription"
                                                              owner:self
                                                            options:nil]
                                objectAtIndex:0];
        [_viewEditDescription setDelegate:self];
    }
    return _viewEditDescription;
}

-(CBCorpExperienceList *)viewExperienceList {
    if (!_viewExperienceList) {
        _viewExperienceList = [[[NSBundle mainBundle] loadNibNamed:@"CBCorpExperienceList"
                                                             owner:self
                                                           options:nil]
                               objectAtIndex:0];
        [_viewExperienceList setDelegate:self];
    }
    return _viewExperienceList;
}

#pragma mark
#pragma mark - CBSelectCoverPhoto Delegates
#pragma mark

-(void)coverSubmitForApproval:(UIImage *)image {
    
    [self submitPhotoForReview:image];
}

-(void)coverPhotoObject:(PFObject *)photoObject {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
        [KVNProgress show];
    });
    
    //either a default cover photo or user submitted cover photo
    //just set the pointer and clear the profile cover photo
    
    [self.userProfile removeObjectForKey:@"coverImage"];
    self.userProfile[@"coverPointer"] = photoObject;
    [self.userProfile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initUI];
            [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
            [KVNProgress showSuccess];
        });
    }];
}

-(void)coverImage:(UIImage *)image {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
        [KVNProgress show];
    });
    
    //new cover image from camera roll
    //clear the cover pointer and set the image
    
    NSData *imageData = UIImagePNGRepresentation(image);
    //make sure the image isn't too big
    NSInteger size = imageData.length;
    if (size < 10485760) {
        
        PFFile *imageFile = [PFFile fileWithName:@"picture.png" data:imageData];
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            if (succeeded) {
                
                self.userProfile[@"coverImage"] = imageFile;
                [self.userProfile removeObjectForKey:@"coverPointer"];
                [self.userProfile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self initUI];
                            [KVNProgress setConfiguration:[Configuration standardProgressConfig]];
                            [KVNProgress showSuccess];
                        });
                        
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                            [KVNProgress showErrorWithStatus:@"Could not update photo"];
                        });
                    }
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
                    [KVNProgress showErrorWithStatus:@"Could not update photo"];
                });
            }
        }];
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KVNProgress dismiss];
            [KVNProgress setConfiguration:[Configuration errorProgressConfig]];
            [KVNProgress showErrorWithStatus:@"Image must be less than 10mb"];
        });
    }
}

#pragma mark
#pragma mark - UITableview delegates
#pragma mark

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.userCat.tableCategories) {
        return [self.userCat.arrayOfCategories count];
    } else if (tableView == self.viewExperienceList.tableExperience) {
        return [self.arrayOfCorpExperience count] + 1;
    }
    else {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    
    if (tableView == self.userCat.tableCategories) {
        
        cell.textLabel.text = (NSString *)[self.userCat.arrayOfCategories objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        
        NSString *str = [self.userCat.dict objectForKey:cell.textLabel.text];
        if ([str isEqualToString:@"YES"]) {
            [self selectCell:cell atIndexPath:indexPath onOrOff:YES fromMethod:NO];
        } else {
            [self selectCell:cell atIndexPath:indexPath onOrOff:NO fromMethod:NO];
        }
    } else if (tableView == self.viewExperienceList.tableExperience) {
        
        if (indexPath.row == 0) {
            
            cell.textLabel.text = @"    Add Experience";
            UIImageView *imageView=[[UIImageView alloc] initWithFrame:CGRectMake(5, 7, 15, 15)];
            //UIImageView *imageView=[[UIImageView alloc] initWithFrame:CGRectMake(5, (CGRectGetMidY(cell.frame) / 2) - (15 / 2), 15, 15)];
            imageView.backgroundColor=[UIColor clearColor];
            [imageView setImage:[UIImage imageNamed:@"Add"]];
            [cell addSubview:imageView];
        } else {
            PFObject *exp = [self.arrayOfCorpExperience objectAtIndex:indexPath.row - 1];
            NSString *str = [NSString stringWithFormat:@"%@, %@ - %@", exp[@"corpsName"], exp[@"year"], exp[@"position"]];
            cell.textLabel.text = str;
            
        }
        cell.textLabel.font = [UIFont systemFontOfSize:12];
    }
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.viewExperienceList.tableExperience) {
        if (indexPath.row == 0) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

-(void)selectCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)path onOrOff:(BOOL)on fromMethod:(BOOL)method {
    
    if (on) {
        if (!method) [self.userCat.tableCategories selectRowAtIndexPath:path animated:NO scrollPosition: UITableViewScrollPositionNone];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        if ([self.userCat.dict objectForKey:cell.textLabel.text]) {
            [self.userCat.dict setObject:@"YES" forKey:cell.textLabel.text];
        }
    } else {
        if (!method) [self.userCat.tableCategories deselectRowAtIndexPath:path animated:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if ([self.userCat.dict objectForKey:cell.textLabel.text]) {
            [self.userCat.dict setObject:@"NO" forKey:cell.textLabel.text];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.userCat.tableCategories) {
        UITableViewCell *tableViewCell = [tableView cellForRowAtIndexPath:indexPath];
        [self selectCell:tableViewCell atIndexPath:indexPath onOrOff:YES fromMethod:YES];
    } else if (tableView == self.viewExperienceList.tableExperience) {
        if (indexPath.row == 0) {
            [self addNewCorpExperience];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.userCat.tableCategories) {
        UITableViewCell *tableViewCell = [tableView cellForRowAtIndexPath:indexPath];
        [self selectCell:tableViewCell atIndexPath:indexPath onOrOff:NO fromMethod:YES];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *obj = [self.arrayOfCorpExperience objectAtIndex:indexPath.row - 1];
    [obj deleteInBackground];
    [self.arrayOfCorpExperience removeObjectAtIndex:indexPath.row - 1];
    [self.viewExperienceList.tableExperience reloadData];
}

#pragma mark
#pragma mark - UIPickerview Delegates
#pragma mark

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == yearPicker) {
        if (row == 0) return @"-Select Year-";
        else return [self.corpExperience.arrayOfYears objectAtIndex:row - 1];
    } else if (pickerView == positionPicker) {
        if (row == 0) return @"-Select Position-";
        else return [self.corpExperience.arrayOfPositions objectAtIndex:row - 1];
    } else if (pickerView == corpPicker) {
        if (row == 0) return @"-Select Corp-";
        else {
            PFObject *corp = [_data.arrayOfAllCorps objectAtIndex:row - 1];
            return corp[@"corpsName"];
        }
    } else {
        return @"error";
    }
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == yearPicker) {
        return [self.corpExperience.arrayOfYears count] + 1;
    } else if (pickerView == positionPicker) {
        return [self.corpExperience.arrayOfPositions count] +1;
    } else if (pickerView == corpPicker) {
        return [_data.arrayOfAllCorps count] +1;
    } else {
        return 1;
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if (pickerView == yearPicker) {
        if (row == 0) self.corpExperience.txtYear.text = @"";
        else self.corpExperience.txtYear.text = [self.corpExperience.arrayOfYears objectAtIndex:row - 1];
    } else if (pickerView == positionPicker) {
        if (row == 0) self.corpExperience.txtPosition.text = @"";
        else self.corpExperience.txtPosition.text = [self.corpExperience.arrayOfPositions objectAtIndex:row - 1];
    } else if (pickerView == corpPicker) {
        if (row == 0) {
            self.corpExperience.selectedCorp = nil;
            self.corpExperience.txtCorpsName.text = @"";
        } else {
            PFObject *corps = [_data.arrayOfAllCorps objectAtIndex:row - 1];
            self.corpExperience.selectedCorp = corps;
            self.corpExperience.txtCorpsName.text = corps[@"corpsName"];
        }
    }
}

#pragma mark
#pragma mark - Scrollview Delegates
#pragma mark

float ht;
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView == self.scrollProfile) {
        CGPoint offset = scrollView.contentOffset;
        if (scrollView.contentOffset.y < 0) {
            self.scrollCoverPhoto.frame = CGRectMake(self.scrollCoverPhoto.frame.origin.x, self.scrollCoverPhoto.frame.origin.y, self.scrollCoverPhoto.frame.size.width, ht - self.scrollProfile.contentOffset.y);
            
        } else if (scrollView.contentOffset.y == 0) {
            self.scrollCoverPhoto.frame = CGRectMake(self.scrollCoverPhoto.frame.origin.x, self.scrollCoverPhoto.frame.origin.y, self.scrollCoverPhoto.frame.size.width, ht);
        } else {
            
            
        }
        
        offset.y = offset.y / 3;
        self.scrollCoverPhoto.contentOffset = offset;
        
    }
    
}

-(NSMutableArray *)arrayOfBadges {
    if (!_arrayOfBadges) {
        _arrayOfBadges = [[NSMutableArray alloc] init];
    }
    return _arrayOfBadges;
}

-(NSMutableArray *)arrayOfSectionLabels {
    if (!_arrayOfSectionLabels) {
        _arrayOfSectionLabels = [[NSMutableArray alloc] init];
    }
    return _arrayOfSectionLabels;
}

-(NSMutableArray *)arrayOfCorpExperience {
    if (!_arrayOfCorpExperience) {
        _arrayOfCorpExperience = [[NSMutableArray alloc] init];
    }
    return _arrayOfCorpExperience;
}

-(NSMutableArray *)arrayOfCorpExperienceLabels {
    if (!_arrayOfCorpExperienceLabels) {
        _arrayOfCorpExperienceLabels = [[NSMutableArray alloc] init];
    }
    return _arrayOfCorpExperienceLabels;
}

-(NSMutableArray *)arrayOfPhotos {
    if (!_arrayOfPhotos) {
        _arrayOfPhotos = [[NSMutableArray alloc] init];
    }
    return _arrayOfPhotos;
}

-(NSMutableArray *)arrayOfSelections {
    if (!_arrayOfSelections) {
        _arrayOfSelections = [[NSMutableArray alloc] init];
    }
    return _arrayOfSelections;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"coverPhotos"]) {
        
        CBSelectCoverPhoto *vc = segue.destinationViewController;
        vc.delegate = self;
    }
}

- (IBAction)btnChat_clicked:(id)sender {
    
    PFUser *user1 = [PFUser currentUser];
    PFUser *user2 = self.userProfile;
    NSString *id1 = user1.objectId;
    NSString *id2 = user2.objectId;
    NSString *roomId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
    //---------------------------------------------------------------------------------------------------------------------------------------------
    CreateMessageItem(user1, user2, roomId, user2[@"nickname"], nil);
    CreateMessageItem(user2, user1, roomId, user1[@"nickname"], nil);
    //---------------------------------------------------------------------------------------------------------------------------------------------
    ChatView *chatView = [[ChatView alloc] initWith:roomId];
    chatView.hidesBottomBarWhenPushed = YES;
    chatView.user2 = user2;
    chatView.isPrivate = YES;
    [self.navigationController pushViewController:chatView animated:YES];
}

- (IBAction)btnReport_clicked:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Report User" message:@"Tell us what happened" delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"Report", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [alert textFieldAtIndex:0].autocorrectionType = UITextAutocorrectionTypeDefault;
    [alert show];
    
}

#pragma mark
#pragma mark - UIAlertView Delegates
#pragma mark

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != alertView.cancelButtonIndex) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text isEqualToString:@""] == NO)
        {
            PFObject *object = [PFObject objectWithClassName:@"reportUsers"];
            object[@"report"] = textField.text;
            object[@"userReporting"] = [PFUser currentUser];
            object[@"userBeingReported"] = self.userProfile;
            
            [object saveEventually];
        }
    }
}
@end
