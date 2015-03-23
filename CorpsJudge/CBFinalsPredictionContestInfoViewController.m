//
//  CBFinalsPredictionContestInfoViewController.m
//  CorpsBoard
//
//  Created by Isaias Favela on 6/30/14.
//  Copyright (c) 2014 Justin Moore. All rights reserved.
//

#import "CBFinalsPredictionContestInfoViewController.h"
#import "CBSingle.h"
#import "CBTerms.h"

@interface CBFinalsPredictionContestInfoViewController () {
    CBSingle *data;
}
- (IBAction)btnTerms_tapped:(id)sender;

@end

@implementation CBFinalsPredictionContestInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    data = [CBSingle data];
}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    [self.navigationItem setHidesBackButton:NO animated:NO];
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backBtnImage = [UIImage imageNamed:@"arrowLeft"];
    [backBtn setBackgroundImage:backBtnImage forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    backBtn.frame = CGRectMake(0, 0, 30, 30);
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn] ;
    self.navigationItem.leftBarButtonItem = backButton;
    
}

- (void)goback {
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnTerms_tapped:(id)sender {
    
    NSString *terms = data.objAdmin[@"contestTerms"];

    CBTerms *termView =
    [[[NSBundle mainBundle] loadNibNamed:@"CBTerms"
                                   owner:self
                                 options:nil]
     objectAtIndex:0];
    [self.view addSubview:termView];
    [termView showInParent:self.view.frame withHTMLString:terms];
}
@end
