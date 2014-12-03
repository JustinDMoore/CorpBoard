//
//  CBEmailLogin.m
//  CorpBoard
//
//  Created by Justin Moore on 11/21/14.
//  Copyright (c) 2014 Justin Moore. All rights reserved.
//

#import "CBEmailLogin.h"
#import "JustinHelper.h"
#import <Parse/Parse.h>
#import "ParseErrors.h"
#import "ProgressHUD.h"
#import "AppConstant.h"
#import "pushnotification.h"


@implementation CBEmailLogin {
    
    IBOutlet UITextField *txtName;
    IBOutlet UITextField *txtEmail;
    IBOutlet UITextField *txtPassword;
    IBOutlet UIButton *btnSignUp;
    id currentResponder;
}

-(void)awakeFromNib {
    [self initUI];
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        // CUSTOM INITIALIZATION HERE
        //[self initUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

-(void)initUI {
    
    self.clipsToBounds = YES;
    txtEmail.delegate = self;
    txtPassword.delegate = self;
    txtPassword.secureTextEntry = YES;

}

-(void)setIsNewUser:(BOOL)isNewUser {
    newUser = isNewUser;
    if (isNewUser) {
        self.lblTitle.text = @"CREATE NEW ACCOUNT";
    } else {
        self.lblTitle.text = @"SIGN INTO EXISTING ACCOUNT";
    }
}

-(void)setDelegate:(id)newDelegate{
    delegate = newDelegate;
}

BOOL cancelled;
- (IBAction)btnCancel_clicked:(id)sender {
    txtEmail.text = @"";
    txtPassword.text = @"";
    cancelled = YES;
    [txtEmail resignFirstResponder];
    [txtPassword resignFirstResponder];
    
    if (![txtEmail isFirstResponder] && ![txtPassword isFirstResponder]) {
        [delegate emailCancelled];
    }
}

- (IBAction)btnSignUp_clicked:(id)sender {
    if ([self checkForEmailAndPassword:nil]) {
        [txtEmail resignFirstResponder];
        [txtPassword resignFirstResponder];
        if (newUser) {
            [self createAccount];
        } else {
            [self signIntoAccountWithEmail:txtEmail.text andPassword:txtPassword.text];
        }
    }
}

-(void)createAccount {
    
//    PFUser *user = [PFUser user];
//    user.username = email;
//    user.password = pw;
//    user.email = email;
//    
//    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (!error) {
//            // Hooray! Let them use the app now.
//            [delegate newUserCreatedFromEmail:email pw:pw];
//            
//        } else {
//            NSString *errorString = [error userInfo][@"error"];
//            // Show the errorString somewhere and let the user try again.
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[ParseErrors getErrorStringForCode:error.code] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//            [alert show];
//            NSLog(@"Error creating account: %@", errorString);
//            
// 
//        }
//    }];
    
    NSString *name		= txtName.text;
    NSString *password	= txtPassword.text;
    NSString *email		= txtEmail.text;
    
  
        [ProgressHUD show:@"Please wait..." Interaction:NO];
        
        PFUser *user = [PFUser user];
        user.username = email;
        user.password = password;
        user.email = email;
        user[PF_USER_EMAILCOPY] = email;
        user[PF_USER_FULLNAME] = name;
        user[PF_USER_FULLNAME_LOWER] = [name lowercaseString];
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
             if (error == nil) {
                 ParsePushUserAssign();
                 [ProgressHUD showSuccess:@"Succeed."];
                 [delegate newUserCreatedFromEmail];
             } else {
                 [ProgressHUD showError:error.userInfo[@"error"]];
             }
         }];
}

-(void)signIntoAccountWithEmail:(NSString *)email andPassword:(NSString *)pw {
    
//    [PFUser logInWithUsernameInBackground:email password:pw
//                                    block:^(PFUser *user, NSError *error) {
//                                        if (user) {
//                                            NSLog(@"email login good");
//                                            [delegate successfulLoginFromEmail];
//                                        } else {
//                                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[ParseErrors getErrorStringForCode:error.code] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//                                            [alert show];
//                                            NSLog(@"%@", error);
//                                            // The login failed. Check error to see why.
//                                        }
//                                    }];


    NSString *username = txtEmail.text;
    NSString *password = txtPassword.text;
    
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error)
     {
         if (user != nil)
         {
             ParsePushUserAssign();
             [delegate successfulLoginFromEmail];
         } else {
             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[ParseErrors getErrorStringForCode:error.code] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
             [alert show];
             NSLog(@"%@", error);
         }
     }];
}

#pragma mark
#pragma mark - UITextField Delegates
#pragma mark

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    currentResponder = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == txtEmail)  {
        if ([textField.text length]) {
            [textField resignFirstResponder];
            [txtPassword becomeFirstResponder];
            currentResponder = txtPassword;
        }
    }

    if (textField == txtPassword) {
        if ([self checkForEmailAndPassword:textField]) {
            [self signIntoAccountWithEmail:txtEmail.text andPassword:txtPassword.text];
        }
    }
    
    return NO;
}

-(BOOL)checkForEmailAndPassword: (UITextField *)textField {
    
    UIAlertView *alert;
    
    if (newUser) {
        if (![txtName.text length]) {
            alert = [[UIAlertView alloc] initWithTitle:@""
                                               message:@"Please enter your name"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            [txtName becomeFirstResponder];
            [alert show];
            return NO;
        }
    }
    
    if (![txtEmail.text length]) {
        alert = [[UIAlertView alloc] initWithTitle:@""
                                           message:@"Please enter a valid email address"
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [txtEmail becomeFirstResponder];
        [alert show];
        return NO;
    } else {
        if (![JustinHelper StringIsValidEmail:txtEmail.text]) {
            alert = [[UIAlertView alloc] initWithTitle:@""
                                               message:@"Please enter a valid email address"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            [txtEmail becomeFirstResponder];
            [alert show];
            return NO;
        }
    }
    
    if (![txtPassword.text length]) {
        alert = [[UIAlertView alloc] initWithTitle:@""
                                           message:@"Please enter a password"
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [txtPassword becomeFirstResponder];
        [alert show];
        return NO;
    }

    return YES;
}

#pragma mark
#pragma mark - Keyboard Notifications
#pragma mark

-(void)keyboardWillShow:(NSNotification*)aNotification {

    self.viewToScroll.frame = CGRectMake(0, 0, self.viewToScroll.frame.size.width, self.viewToScroll.frame.size.height);
    
    NSDictionary *userInfo = [aNotification userInfo];
    
    CGRect rect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:curve animations:^{
        self.viewToScroll.frame = CGRectMake(self.viewToScroll.frame.origin.x, self.viewToScroll.frame.origin.y - (rect.size.height / (newUser ? 1.3 : 1.7)), self.viewToScroll.frame.size.width, self.viewToScroll.frame.size.height);
    } completion:nil];
    
}

-(void)keyboardWillHide:(NSNotification*)aNotification {

    
    NSDictionary *userInfo = [aNotification userInfo];
    
    CGRect rect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:curve animations:^{
        self.viewToScroll.frame = CGRectMake(self.viewToScroll.frame.origin.x, 0, self.viewToScroll.frame.size.width, self.viewToScroll.frame.size.height);
    } completion:nil];
}

- (IBAction)btnForgotPassword_clicked:(id)sender {
    
    if ([txtEmail.text length]) {
        //make sure it's a valid email
        if (![JustinHelper StringIsValidEmail:txtEmail.text]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please enter a valid email address." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            [txtEmail becomeFirstResponder];
        } else {
            //valid email, check to make sure we have account for it
            [PFUser requestPasswordResetForEmailInBackground:txtEmail.text block:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    if (succeeded) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"An email will be sent to %@ with instructions to reset your password.", txtEmail.text] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Unable to reset password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[ParseErrors getErrorStringForCode:error.code] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                }
            }];
            [PFUser requestPasswordResetForEmailInBackground:@"email@example.com"];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Enter your email address to reset your password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

@end
