//
//  MenuViewController.swift
//  CorpBoard
//
//  Created by Justin Moore on 5/7/16.
//  Copyright © 2016 Justin Moore. All rights reserved.
//

import UIKit
import CoreLocation
import JSBadgeView
import PulsingHalo
import MWFeedParser
import ImageSlideshow
import AFDateHelper

class MenuViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, delegateUserProfile, delegateCreateAccount, delegateUserLocation {

    enum scrollDir {
        case None
        case Right
        case Left
        case Up
        case Down
        case Crazy
    }
    
    enum opening {
        case None
        case Profile
        case Messages
        case LiveChat
        case NearMe
        case Map
        case Store
    }
    
    //MARK:-
    //MARK:Properties
    let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
    let BUTTON_CORNER_RADIUS: CGFloat = 8.0
    let BUTTON_BORDER_WIDTH: CGFloat = 1.0
    let BUTTON_BORDER_COLOR = UIColor.blackColor().CGColor
    
    var lastShowString = ""
    var nextShowString = ""
    var arrayOfLastShows = [PShow]()
    var arrayOfShowsYesterday = [PShow]()
    var arrayOfShowsToday = [PShow]()
    var arrayOfShowsTomorrow = [PShow]()
    var arrayOfNextShows = [PShow]()
    var arrayOfShowsForTable1 = [PShow]()
    var arrayOfShowsForTable2 = [PShow]()
    var badgeMessages = JSBadgeView()
    var badgeAdmin = JSBadgeView()
    var btnAdminBarButton = UIBarButtonItem()
    var btnAdminButton = UIButton()
    var showToOpen: PShow?
    var lastContentOffSet: CGFloat = 0.0
    var isScrolling = false
    var scrollDirection = scrollDir.None
    var tryingToOpen = opening.None
    var viewLocationForDelegate = LocationServicesPermission()
    var privateChatSegue = false
    
    //MARK:-
    //MARK:Outlets

    @IBOutlet weak var scrollMain: UIScrollView!
    @IBOutlet weak var contentMainView: UIView!
    @IBOutlet weak var imgCavalier: UIImageView!
    @IBOutlet weak var slideBanners: ImageSlideshow!
    @IBOutlet weak var btnNearMe: UIButton!
    @IBOutlet weak var viewProfile: UIControl!
    @IBOutlet weak var btnLiveChat: UIButton!
    @IBOutlet weak var btnMessages: UIButton!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblMessages: UILabel!
    @IBOutlet weak var lblLiveChat: UILabel!
    @IBOutlet weak var lblNearMe: UILabel!
    @IBOutlet weak var lblTourMap: UILabel!
    @IBOutlet weak var viewRecentShows: ClipView!
    @IBOutlet weak var scrollViewShows: UIScrollView!
    @IBOutlet weak var tableLastShows: UITableView!
    @IBOutlet weak var tableNextShows: UITableView!
    @IBOutlet weak var contentViewShows: UIView!
    @IBOutlet weak var lblShowsHeader: UILabel!
    @IBOutlet weak var btnSeeAll: UIButton!
    @IBOutlet weak var pageShows: UIPageControl!
    @IBOutlet weak var imgBannerMiddle: UIImageView! //TODO: Finals prediction?
    @IBOutlet weak var viewRankings: ClipView!
    @IBOutlet weak var scrollTopTwelve: UIScrollView!
    @IBOutlet weak var tableTopFour: UITableView!
    @IBOutlet weak var tableTopEight: UITableView!
    @IBOutlet weak var tableTopTwelve: UITableView!
    @IBOutlet weak var lblTopTwelveHeader: UILabel!
    @IBOutlet weak var btnSeeAllRankings: UIButton!
    @IBOutlet weak var contentViewTopTwelve: UIView!
    @IBOutlet weak var pageTopTwelve: UIPageControl!
    @IBOutlet weak var btnSeeAllNews: UIButton!
    @IBOutlet weak var viewNews: ClipView!
    @IBOutlet weak var collectionNews: UICollectionView!
    @IBOutlet weak var viewShop: UIView!
    @IBOutlet weak var viewSupport: UIControl!
    @IBOutlet weak var viewFeedback: UIControl!
    @IBOutlet weak var viewAboutTheCorps: UIControl!
    @IBOutlet weak var viewExtras: UIView!
    @IBOutlet weak var viewLinks: UIView!
    @IBOutlet weak var lblVersion: UILabel!
    @IBOutlet weak var lblCopyright: UILabel!
    @IBOutlet weak var btnDCI: UIButton!
    @IBOutlet weak var btnProfile: UIButton!
    @IBOutlet weak var btnTourMap: UIButton!
    @IBOutlet weak var btnSeeDailySchedule: UIButton!
    @IBOutlet weak var lblTaskLocation: UILabel!
    @IBOutlet weak var lblTask: UILabel!
    
    //MARK:-
    //MARK:Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initVariables()
        self.initUI()
        self.setupShows()
        self.initNewsFeed()
        Server.sharedInstance.delegateLocation = self
        Server.sharedInstance.getUnreadMessagesForUser()
        self.sortScores()
        self.checkForNewVersion()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let imageView = UIImageView(frame: CGRectMake(130, 20, 20, 54))
        imageView.image = UIImage(named: "title")
        imageView.contentMode = .ScaleAspectFit
        self.navigationItem.titleView = imageView
        
        //update the cadets current activity
        self.updateCurrentTask()
    }

    func updateCurrentTask() {
        self.lblTaskLocation.text = Server.sharedInstance.currentLocation
        self.lblTask.text = Server.sharedInstance.currentTask
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //TODO: Do I need this line??????
        //UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName: UIFont(name: "Helvetica NeueUI", size: 20)!, NSForegroundColorAttributeName:UIColor.whiteColor()]
    }
    
    func setupShows() {
        if Server.sharedInstance.arrayOfAllShows?.count > 0 {
            self.prepareShowsForTable()
            self.pageShows.hidden = false
            self.scrollViewShows.hidden = false
            self.lblShowsHeader.hidden = false
            self.btnSeeAll.hidden = false
        } else {
            print("Error: No shows to set up.")
        }
    }
    
    func initVariables() {
        
        self.collectionNews.registerClass(CBNewsCell.self, forCellWithReuseIdentifier: "CBNewsCell")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "    ",
                                                                style: UIBarButtonItemStyle.Plain,
                                                                target: nil,
                                                                action: nil)
    }
    
    func loadProfile() {
        self.viewProfile.backgroundColor = self.tableLastShows.backgroundColor
        //set admin
        if Server.sharedInstance.adminMode {
            self.navigationController?.navigationBarHidden = false
            self.navigationItem.setHidesBackButton(false, animated: false)
            self.btnAdminButton = UIButton(type: .Custom)
            let admImage = UIImage(named: "admin_admin")
            self.btnAdminButton.setBackgroundImage(admImage, forState: .Normal)
            self.btnAdminButton.addTarget(self, action: #selector(MenuViewController.admin), forControlEvents: .TouchUpInside)
            self.btnAdminButton.frame = CGRectMake(0, 0, 30, 30)
            self.btnAdminButton.addSubview(self.badgeAdmin)
            self.btnAdminBarButton = UIBarButtonItem(customView: self.btnAdminButton)
            self.navigationItem.leftBarButtonItem = self.btnAdminBarButton
            self.setAdminBadge()
        } else {
            self.navigationController?.navigationBarHidden = false
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
    }
    
    func initUI() {
        self.loadProfile()
        self.pulse()
        
        let buttonColor = UISingleton.sharedInstance.maroon
        let textColor = UISingleton.sharedInstance.gold
        
        self.btnProfile.tintColor = buttonColor
        self.btnMessages.tintColor = buttonColor
        self.btnLiveChat.tintColor = buttonColor
        self.btnNearMe.tintColor = buttonColor
        self.btnTourMap.tintColor = buttonColor
        
        lblUserName.textColor = textColor
        lblMessages.textColor = textColor
        lblLiveChat.textColor = textColor
        lblNearMe.textColor = textColor
        lblTourMap.textColor = textColor
        
        self.automaticallyAdjustsScrollViewInsets = false
        //self.view.backgroundColor = self.viewAppTitle.backgroundColor
        self.contentMainView.backgroundColor = UIColor.clearColor()
        
        //display app version to user
        let info = NSBundle.mainBundle().infoDictionary
        let version = info!["CFBundleShortVersionString"] as! String
        self.lblVersion.text = version
        
        //disclosure arrows
        let disclosure1 = UITableViewCell()
        self.btnSeeAll.addSubview(disclosure1)
        disclosure1.frame = CGRectMake(25, 1, self.btnSeeAll.bounds.size.width, self.btnSeeAll.bounds.size.height)
        disclosure1.accessoryType = .DisclosureIndicator
        disclosure1.userInteractionEnabled = false
        let img1 = UIImageView(image: UIImage(named: "disclosure"))
        img1.frame = CGRectMake(0, 0, 20, 20)
        disclosure1.accessoryView = img1
        disclosure1.accessoryView?.tintColor = textColor
        btnSeeAll.setTitleColor(textColor, forState: .Normal)
        
        let disclosure2 = UITableViewCell()
        self.btnSeeAllRankings.addSubview(disclosure2)
        disclosure2.frame = CGRectMake(25, 1, self.btnSeeAllRankings.bounds.size.width, self.btnSeeAllRankings.bounds.size.height)
        disclosure2.accessoryType = .DisclosureIndicator
        disclosure2.userInteractionEnabled = false
        let img2 = UIImageView(image: UIImage(named: "disclosure"))
        img2.frame = CGRectMake(0, 0, 20, 20)
        disclosure2.accessoryView = img2
        disclosure2.tintColor = textColor
        
        let disclosure3 = UITableViewCell()
        self.btnSeeAllNews.addSubview(disclosure3)
        disclosure3.frame = CGRectMake(25, 1, self.btnSeeAllNews.bounds.size.width, self.btnSeeAllNews.bounds.size.height)
        disclosure3.accessoryType = .DisclosureIndicator
        disclosure3.userInteractionEnabled = false
        let img3 = UIImageView(image: UIImage(named: "disclosure"))
        img3.frame = CGRectMake(0, 0, 20, 20)
        disclosure3.accessoryView = img3
        disclosure3.tintColor = textColor
        
        let disclosure4 = UITableViewCell()
        self.btnSeeDailySchedule.addSubview(disclosure4)
        disclosure4.frame = CGRectMake(25, 1, self.btnSeeDailySchedule.bounds.size.width, self.btnSeeDailySchedule.bounds.size.height)
        disclosure4.accessoryType = .DisclosureIndicator
        disclosure4.userInteractionEnabled = false
        let img4 = UIImageView(image: UIImage(named: "disclosure"))
        img4.frame = CGRectMake(0, 0, 20, 20)
        disclosure4.accessoryView = img4
        disclosure4.tintColor = textColor

        //top 12
        self.pageTopTwelve.hidden = true
        self.lblTopTwelveHeader.hidden = true
        self.btnSeeAllRankings.hidden = true
        self.scrollTopTwelve.hidden = true
        self.scrollTopTwelve.canCancelContentTouches = true
        self.scrollTopTwelve.delaysContentTouches = true
        self.scrollTopTwelve.userInteractionEnabled = true
        self.scrollTopTwelve.exclusiveTouch = true
        self.scrollTopTwelve.contentSize = CGSizeMake(self.scrollTopTwelve.frame.size.width * 3, self.scrollTopTwelve.frame.size.height)
        
        // Recent Shows
        self.pageShows.hidden = true
        self.lblShowsHeader.hidden = true
        self.btnSeeAll.hidden = true
        self.scrollViewShows.hidden = true
        self.scrollViewShows.canCancelContentTouches = true
        self.scrollViewShows.delaysContentTouches = true
        self.scrollViewShows.userInteractionEnabled = true
        self.scrollViewShows.exclusiveTouch = true
        self.scrollViewShows.contentSize = self.contentViewShows.frame.size
        self.contentViewShows.userInteractionEnabled = true
        self.contentViewShows.exclusiveTouch = true
        
        //banners
        slideBanners.backgroundColor = UIColor.whiteColor()
        slideBanners.slideshowInterval = 5.0
        slideBanners.pageControlPosition = .Hidden
        slideBanners.pageControl.currentPageIndicatorTintColor = UIColor.lightGrayColor();
        slideBanners.pageControl.pageIndicatorTintColor = UIColor.blackColor();
        slideBanners.contentScaleMode = .ScaleToFill
        slideBanners.setImageInputs(Server.sharedInstance.arrayOfBannerImages!)

        //buttons
        self.viewAboutTheCorps.layer.cornerRadius = BUTTON_CORNER_RADIUS
        self.viewFeedback.layer.cornerRadius = BUTTON_CORNER_RADIUS
        self.viewShop.layer.cornerRadius = BUTTON_CORNER_RADIUS
        self.viewSupport.layer.cornerRadius = BUTTON_CORNER_RADIUS
        
        self.viewAboutTheCorps.layer.borderColor = BUTTON_BORDER_COLOR
        self.viewFeedback.layer.borderColor = BUTTON_BORDER_COLOR
        self.viewShop.layer.borderColor = BUTTON_BORDER_COLOR
        self.viewSupport.layer.borderColor = BUTTON_BORDER_COLOR
        
        self.viewAboutTheCorps.layer.borderWidth = BUTTON_BORDER_WIDTH
        self.viewFeedback.layer.borderWidth = BUTTON_BORDER_WIDTH
        self.viewShop.layer.borderWidth = BUTTON_BORDER_WIDTH
        self.viewSupport.layer.borderWidth = BUTTON_BORDER_WIDTH
        
        //news
        self.collectionNews.backgroundColor = UIColor.clearColor()
        
        //calculate main scroll content
        //for scrollMain contentsize - per the docs
        for view in self.contentMainView.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        self.scrollMain.canCancelContentTouches = true
        self.scrollMain.delaysContentTouches = true
        self.scrollMain.userInteractionEnabled = true
        self.scrollMain.exclusiveTouch = true
        //self.scrollMain.frame = CGRectMake(0, 0, self.scrollMain.frame.size.width, self.scrollMain.frame.size.height)
    }
    
//    func bannerTapped(sender: UIButton) {
////        let bannerObj = Server.sharedInstance.arrayOfBannerObjects![sender.tag]
////        if (bannerObj["link"] as! String?) != nil {
////            self.openWebViewWithLink(bannerObj["link"] as! String, title: bannerObj["desc"] as! String, subTitle: bannerObj["link"] as! String)
////        }
//    }
    
    func openWebViewWithLink(link: String, title: String, subTitle: String) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let web = storyboard.instantiateViewControllerWithIdentifier("web") as? CBWebViewController {
            web.webURL = link
            web.websiteTitle = title
            web.websiteSubTitle = subTitle
            self.presentViewController(web, animated: true, completion: nil)
        }
    }

    func pulse() {
        let halo = PulsingHaloLayer()
        halo.position = self.btnNearMe.center
        halo.radius = 20
        halo.animationDuration = 2
        halo.backgroundColor = UIColor.whiteColor().CGColor
        btnProfile.layer.addSublayer(halo)
        //viewProfile.layer.addSublayer(halo)
        //self.viewProfile.bringSubviewToFront(self.btnNearMe)
    }
    
    func initNewsFeed() {
        self.collectionNews.reloadData()
    }
    
    func openShow(sender: UIButton) {
        var parentCell = sender.superview
        while !(parentCell?.isKindOfClass(UITableViewCell))! {
            parentCell = parentCell?.superview
        }
        var parentView = parentCell?.superview
        while !(parentView?.isKindOfClass(UITableView))! {
            parentView = parentView?.superview
        }
        let tableView = parentView as! UITableView
        let buttonPosition = sender.convertPoint(CGPointZero, toView: tableView)
        let indPath = tableView.indexPathForRowAtPoint(buttonPosition)
        if tableView === self.tableLastShows {
            self.openShowAtIndex(indPath!, tableView: self.tableLastShows)
        } else if tableView === self.tableNextShows {
            self.openShowAtIndex(indPath!, tableView: self.tableNextShows)
        }
    }
    
    func sortScores() {
        if Server.sharedInstance.arrayOfWorldClass?.count > 0 {
            Server.sharedInstance.arrayOfWorldClass!.sortInPlace({ $0.lastScore > $1.lastScore })
        }
        self.pageTopTwelve.hidden = false
        self.scrollTopTwelve.hidden = false
        self.lblTopTwelveHeader.hidden = false
        self.btnSeeAllRankings.hidden = false
        self.tableTopFour.reloadData()
        self.tableTopEight.reloadData()
        self.tableTopTwelve.reloadData()
    }
    
    func prepareShowsForTable() {
        self.getPreviousAndNextShows()
        if self.arrayOfShowsForTable2.count > 0 {
            self.tableNextShows.reloadData()
        } else {
            self.tableNextShows.hidden = true
        }
        if self.arrayOfShowsForTable1.count > 0 {
            self.tableLastShows.reloadData()
        } else {
            self.tableLastShows.hidden = true
        }
        if self.arrayOfShowsForTable1.count < 1 || self.arrayOfShowsForTable2.count < 1 {
            self.scrollViewShows.contentSize = CGSizeMake(self.scrollViewShows.contentSize.width / 2, self.scrollViewShows.contentSize.height)
            self.pageShows.numberOfPages = 0
            self.scrollViewShows.scrollEnabled = false
        }
    }
    
    func getPreviousAndNextShows() {
        self.arrayOfLastShows = []
        self.arrayOfShowsYesterday = []
        self.arrayOfShowsToday = []
        self.arrayOfShowsTomorrow = []
        self.arrayOfNextShows = []
        self.arrayOfShowsForTable1 = []
        self.arrayOfShowsForTable2 = []
        
        if Server.sharedInstance.arrayOfAllShows?.count > 0 {
            Server.sharedInstance.arrayOfAllShows!.sortInPlace({ $0.showDate.compare($1.showDate) == NSComparisonResult.OrderedAscending })
        }
        
        let lastShow = Server.sharedInstance.arrayOfAllShows?.last
        let lastShowDate = (lastShow?.showDate)! as NSDate
        
        //if today is after finals, just get the last four shows
        if lastShowDate.isInPast() {
            let i = Server.sharedInstance.arrayOfAllShows?.indexOf(lastShow!)
            var x = 0
            while x < 4 {
                self.arrayOfShowsYesterday.append(Server.sharedInstance.arrayOfAllShows![i!-x])
                x += 1
            }
            self.arrayOfShowsForTable1 = self.arrayOfShowsYesterday
            lastShowString = "Latest Shows"
        } else {
            //otherwise proceed as normal
            //get shows for yesterday, today, and tomorrow
            if let shows = Server.sharedInstance.arrayOfAllShows as [PShow]! {
                for show in shows {
                    if show.showDate.isYesterday() {
                        self.arrayOfShowsYesterday.append(show)
                    }
                    if show.showDate.isToday() {
                        self.arrayOfShowsToday.append(show)
                    }
                    if show.showDate.isTomorrow() {
                        self.arrayOfShowsTomorrow.append(show)
                    }
                }
            }
            //get latests show prior to yesterday
            if self.arrayOfLastShows.count < 1 {
                var arrayForLast = [PShow]()
                if self.arrayOfShowsYesterday.count < 1 { //if yesterday is empty, use it
                    arrayForLast = self.arrayOfShowsYesterday
                } else {
                    arrayForLast = self.arrayOfLastShows
                }
                var numberOfDays = 2
                var foundLastDate = false
                repeat {
                    let days = NSDate().dateBySubtractingDays(2)
                    if let shows = Server.sharedInstance.arrayOfAllShows as [PShow]! {
                        for show in shows {
                            if show.showDate.isEqualToDateIgnoringTime(days) {
                                arrayForLast.append(show)
                                foundLastDate = true
                            }
                        }
                        numberOfDays += 1
                        if numberOfDays > 60 { break }
                    }
                    
                } while !foundLastDate
            }
        }
        
        //get the next show after tomorrow
        if self.arrayOfLastShows.count < 1 {
            var arrayForNext = [PShow]()
            if self.arrayOfShowsTomorrow.count < 1 { // if tomorrow is empty, use it
                    arrayForNext = self.arrayOfShowsTomorrow
            } else { //otherwise, use next shows
                arrayForNext = self.arrayOfNextShows
            }
            
            var numberOfDays = 2
            var foundNextDate = false
            repeat {
                let days = NSDate().dateByAddingDays(numberOfDays)
                if let shows = Server.sharedInstance.arrayOfAllShows as [PShow]! {
                    for show in shows {
                        if show.showDate.isEqualToDateIgnoringTime(days) {
                            arrayForNext.append(show)
                            foundNextDate = true
                        }
                    }
                    numberOfDays += 1
                    if numberOfDays > 60 { break }
                }
            } while !foundNextDate
        }
        
        //now see what we have and assign the tables
        if self.arrayOfShowsToday.count > 0 {
            self.arrayOfShowsForTable1 = self.arrayOfShowsToday
            if self.arrayOfShowsTomorrow.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfShowsTomorrow
            } else if self.arrayOfNextShows.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfNextShows
            }
        } else if self.arrayOfShowsYesterday.count > 0 {
            self.arrayOfShowsForTable1 = self.arrayOfShowsYesterday
            if self.arrayOfShowsTomorrow.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfShowsTomorrow
            } else if self.arrayOfNextShows.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfNextShows
            }
        } else if self.arrayOfLastShows.count > 0 {
            self.arrayOfShowsForTable1 = self.arrayOfLastShows
            if self.arrayOfShowsTomorrow.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfShowsTomorrow
            } else if self.arrayOfNextShows.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfNextShows
            }
        } else if self.arrayOfShowsTomorrow.count > 0 {
            self.arrayOfShowsForTable1 = self.arrayOfShowsTomorrow
            if self.arrayOfNextShows.count > 0 {
                self.arrayOfShowsForTable2 = self.arrayOfNextShows
            }
        }
        
        //set the date label for table 1 shows
        if self.arrayOfShowsForTable1.count > 0 {
            if let show = self.arrayOfShowsForTable1.first {
                if show.showDate.isToday() {
                    lastShowString = "Shows Today"
                } else if show.showDate.isYesterday() {
                    lastShowString = "Yesterday"
                } else if show.showDate.isTomorrow() {
                    lastShowString = "Shows Tomorrow"
                } else {
                    let formatter = NSDateFormatter()
                    formatter.dateFormat = "EEEE M/dd"
                    lastShowString = formatter.stringFromDate(show.showDate)
                }
            }
        }
        
        //set the date label for table 2 shows
        if self.arrayOfShowsForTable2.count > 0 {
            if let show = self.arrayOfShowsForTable2.first {
                if show.showDate.isToday() {
                    nextShowString = "Shows Today"
                } else if show.showDate.isTomorrow() {
                    nextShowString = "Shows Tomorrow"
                } else {
                    let formatter = NSDateFormatter()
                    formatter.dateFormat = "EEEE M/dd"
                    nextShowString = formatter.stringFromDate(show.showDate)
                }
            }
        }
        
        self.lblShowsHeader.text = lastShowString
    }
    
    //MARK:-
    //MARK:UITableView
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView === self.tableLastShows {
            if self.arrayOfShowsForTable1.count > 0 {
                if self.arrayOfShowsForTable1.count > 4 {
                    return 4
                } else {
                    return self.arrayOfShowsForTable1.count
                }
            } else {
                return 0
            }
        } else if tableView === self.tableNextShows {
            if self.arrayOfShowsForTable2.count > 0 {
                if self.arrayOfShowsForTable2.count > 4 {
                    return 4
                } else {
                    return self.arrayOfShowsForTable2.count
                }
            } else {
                return 0
            }
        } else if tableView === self.tableTopFour || tableView === self.tableTopEight || tableView === self.tableTopFour {
            return 4
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        let show: PShow
        let lblShowName: UILabel
        let lblShowLocation: UILabel
        var btnScores = UIButton()
        
        if tableView === self.tableLastShows {
            if self.arrayOfShowsForTable1.count > 0 {
                show = self.arrayOfShowsForTable1[indexPath.row]
                if show.isShowOver {
                    cell = self.tableLastShows.dequeueReusableCellWithIdentifier("scores")!
                    lblShowName = cell.viewWithTag(1) as! UILabel
                    lblShowLocation = cell.viewWithTag(2) as! UILabel
                    btnScores = cell.viewWithTag(3) as! UIButton
                    btnScores.addTarget(self, action: #selector(MenuViewController.openShow(_:)), forControlEvents: .TouchUpInside)
                    lblShowName.text = show.showName
                    lblShowLocation.text = show.showLocation
                    btnScores.layer.borderWidth = 1.0
                    btnScores.layer.borderColor = UISingleton.sharedInstance.appTint.CGColor
                    btnScores.layer.cornerRadius = 4.0
                    btnScores.titleLabel?.text = " Scores "
                    btnScores.layer.masksToBounds = true
                    btnScores.titleLabel?.font = UIFont.systemFontOfSize(12)
                    btnScores.setTitleColor(UISingleton.sharedInstance.appTint, forState: .Normal)
                    
                    if show.exception.characters.count > 0 {
                        let lblException = UILabel(frame: CGRectMake(btnScores.frame.origin.x - 5, btnScores.frame.origin.y + 5, btnScores.frame.size.width, 20))
                        lblException.font = UIFont.systemFontOfSize(12)
                        lblException.textColor = UIColor.lightGrayColor()
                        lblException.text = show.exception
                        lblException.textAlignment = .Right
                        lblException.sizeToFit()
                        cell.addSubview(lblException)
                    } else {
                        btnScores.hidden = false
                    }
                    
                } else {
                    cell = self.tableLastShows.dequeueReusableCellWithIdentifier("show")!
                    lblShowName = cell.viewWithTag(1) as! UILabel
                    lblShowLocation = cell.viewWithTag(2) as! UILabel
                    lblShowName.text = show.showName
                    lblShowLocation.text = show.showLocation
                }
            }
            
        } else if tableView === self.tableNextShows {
            
            cell = self.tableNextShows.dequeueReusableCellWithIdentifier("show")!
            lblShowName = cell.viewWithTag(1) as! UILabel
            lblShowLocation = cell.viewWithTag(2) as! UILabel
            
            if self.arrayOfShowsForTable2.count > 0 {
                show = self.arrayOfShowsForTable2[indexPath.row]
                lblShowName.text = show.showName
                lblShowLocation.text = show.showLocation
            }
        }
        
        let corps: PCorps
        let lblCorpsName: UILabel
        let lblPosition: UILabel
        let lblScore: UILabel
        let lblScoreDate: UILabel
        let imgView: UIImageView
        
        if tableView === self.tableTopFour || tableView === self.tableTopEight || tableView === self.tableTopTwelve {
            cell = self.tableTopFour.dequeueReusableCellWithIdentifier("rank")!
            lblPosition = cell.viewWithTag(4) as! UILabel
            lblCorpsName = cell.viewWithTag(1) as! UILabel
            lblScore = cell.viewWithTag(2) as! UILabel
            lblScoreDate = cell.viewWithTag(3) as! UILabel
            imgView = cell.viewWithTag(5) as! UIImageView
            
            if Server.sharedInstance.arrayOfWorldClass?.count > 0 {
                var increment = 0
                if tableView === self.tableTopFour { increment = 0 }
                if tableView === self.tableTopEight { increment = 4 }
                if tableView === self.tableTopTwelve { increment = 8 }
                
                corps = Server.sharedInstance.arrayOfWorldClass![indexPath.row + increment]
                lblPosition.text = "\(indexPath.row + 1 + increment)"
                lblCorpsName.text = corps.corpsName
                //get corps logo
                if corps.logo != nil {
                    corps.logo!.getDataInBackgroundWithBlock({ (data: NSData?, err: NSError?) in
                        if err == nil {
                            imgView.image = UIImage(data: data!)
                        } else {
                            imgView.image = nil
                            print("Could not display logo for \(corps.corpsName)")
                        }
                    })
                } else {
                    imgView.image = nil
                    print("Could not display logo for \(corps.corpsName)")
                }
                
                if corps.lastScoreDate.isToday() {
                    lblScoreDate.text = "Today"
                } else if corps.lastScoreDate.isYesterday() {
                    lblScoreDate.text = "Yesterday"
                } else {
                    let days = corps.lastScoreDate.daysBeforeDate(NSDate())
                    if days > 1 {
                        lblScoreDate.text = "\(days) days ago"
                    } else if days <= 0 {
                        lblScoreDate.text = ""
                    } else {
                        lblScoreDate.text = "\(days) day ago"
                    }
                }
                
                if corps.lastScore.characters.count > 0 {
                    lblScore.text = corps.lastScore
                } else {
                    lblScore.text = "0"
                    lblScoreDate.text = "No score"
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.openShowAtIndex(indexPath, tableView: tableView)
    }
    
    
    //MARK:-
    //MARK:UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if News.sharedInstance.arrayOfNewsItemsToDisplay.count >= 6 { return 6 }
        else { return News.sharedInstance.arrayOfNewsItemsToDisplay.count }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellIdentifier = "cell\(indexPath.row)"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! CBNewsCell
        let item = News.sharedInstance.arrayOfNewsItemsToDisplay[indexPath.row]
        let dateLabel = UILabel(frame: CGRectMake(8, 8, 190, 21))
        dateLabel.font = UIFont(name: "HelveticaNeue-Light", size: 12)
        dateLabel.text = News.sharedInstance.dateForNews(item.date)
        dateLabel.textColor = UIColor.whiteColor()
        dateLabel.sizeToFit()
        cell.addSubview(dateLabel)
        
        let titleLabel = UILabel(frame: CGRectMake(8, dateLabel.frame.origin.y + dateLabel.frame.size.height + 3, 190, 60))
        titleLabel.font = UIFont.systemFontOfSize(14)
        titleLabel.text = item.title
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = .ByTruncatingTail
        titleLabel.sizeToFit()
        cell.addSubview(titleLabel)
        
        let imgFrom = UIImageView(frame: CGRectMake(cell.frame.size.width - 30, cell.frame.size.height - 25, 30, 30))
        imgFrom.image = UIImage(named: "DCI_LOGO_Transparent3")
        cell.addSubview(imgFrom)
        
        let lblFrom = UILabel(frame: CGRectMake(imgFrom.frame.origin.x + 3, cell.frame.size.height - 17, 190, 21))
        lblFrom.font = UIFont.systemFontOfSize(10)
        lblFrom.text = ""
        lblFrom.textColor = UIColor.blueColor()
        lblFrom.sizeToFit()
        cell.addSubview(lblFrom)
        
        cell.lblDate = dateLabel
        cell.lblTitle = titleLabel
        
        cell.clipsToBounds = true
        cell.layer.cornerRadius = 8
        cell.colorNumber = News.sharedInstance.arrayOfColors[indexPath.row]
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let itemForWeb = News.sharedInstance.arrayOfNewsItemsToDisplay[indexPath.row]
        self.openWebViewWithLink(itemForWeb.link, title: "Drum Corps International", subTitle: itemForWeb.title)
    }
    
    //MARK:-
    //MARK:UIScrollView
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView === self.scrollMain {
            if scrollView.contentOffset.y < -128 {
                scrollView.contentOffset = CGPointMake(0, -128)
            }
        }
        if lastContentOffSet > scrollView.contentOffset.x {
            self.scrollDirection = .Right
        } else if lastContentOffSet < scrollView.contentOffset.x {
            self.scrollDirection = .Left
        }
        
        lastContentOffSet = scrollView.contentOffset.x
        
        if scrollView === self.scrollViewShows {
            let pageWidth = scrollViewShows.frame.size.width
            let fractionalPage = self.scrollViewShows.contentOffset.x / pageWidth
            let page = lround(Double(fractionalPage))
            self.pageShows.currentPage = page
        }
        
        if scrollView === self.scrollTopTwelve {
            let pageWidth = self.scrollTopTwelve.frame.size.width
            let fractionalPage = self.scrollTopTwelve.contentOffset.x / pageWidth
            let page = lround(Double(fractionalPage))
            self.pageTopTwelve.currentPage = page
        }
        
//        if scrollView === self.scrollBanners {
//            //the user scrolled mannually, so reset the counter
//            self.bannerCounter = 0
//        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView === self.scrollViewShows {
            if self.pageShows.currentPage == 0 {
                self.lblShowsHeader.text = self.lastShowString
            } else {
                self.lblShowsHeader.text = self.nextShowString
            }
        }
    }
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //        if scrollView === self.collectionNews {
        //            let point = targetContentOffset
        //            let layout = self.collectionNews.collectionViewLayout as! UICollectionViewFlowLayout
        //            let visibleWidth = layout.minimumInteritemSpacing + layout.itemSize.width
        //            let indexOfItemToSnap = round(point.x / visibleWidth)
        //            if indexOfItemToSnap + 1 == self.collectionNews.numberOfItemsInSection(0) { //last item
        //                targetContentOffset = CGPointMake(self.collectionNews.contentSize.width - self.collectionNews.bounds.size.width, 0)
        //            } else {
        //                targetContentOffset = CGPointMake(indexOfItemToSnap * visibleWidth, 0)
        //            }
        //        }
    }
    
    //MARK:-
    //MARK: Actions
    @IBAction func feedback(sender: AnyObject) {
        self.performSegueWithIdentifier("feedback", sender: self)
    }
    
    @IBAction func rankings(sender: AnyObject) {
        self.performSegueWithIdentifier("rankings", sender: self)
    }
    
    @IBAction func schedules(sender: AnyObject) {
        self.performSegueWithIdentifier("schedules", sender: self)
    }
    
    @IBAction func shows(sender: AnyObject) {
        self.performSegueWithIdentifier("shows", sender: self)
    }
    
    @IBAction func aboutTheCorps(sender: AnyObject) {
        self.performSegueWithIdentifier("corps", sender: self)
    }
    
    @IBAction func news(sender: AnyObject) {
        self.performSegueWithIdentifier("news", sender: self)
    }
    
    @IBAction func link(sender: AnyObject) {
        switch sender.tag {
        case 0:
            self.openWebViewWithLink("http://yea.org", title: "Yea!", subTitle: "Youth Education in the Arts")
        case 1:
            self.openWebViewWithLink("http://cadets.org", title: "The Cadets", subTitle: "www.cadets.org")
        case 2:
            self.openWebViewWithLink("http://yea.org/programs/cadets/cadets2", title: "Cadets 2", subTitle: "http://yea.org/programs/cadets/cadets2")
        case 3:
            self.openWebViewWithLink("http://usbands.org", title: "USBands", subTitle: "www.usbands.org")
        case 4:
            self.openWebViewWithLink("http://yea.org/programs/cadets/cadets-winter-perc" , title: "Cadets Winter Percussion", subTitle: "http://yea.org/programs/cadets/cadets-winter-perc")
        case 5:
            self.openWebViewWithLink("http://yea.org/programs/cadets/cadets-winter-guard" , title: "Cadets Winter Guard", subTitle: "http://yea.org/programs/cadets/cadets-winter-guard")
        default: break
        }
    }
    
    @IBAction func admin() {
        self.performSegueWithIdentifier("admin", sender: self)
    }
    
    @IBAction func btnProfile(sender: AnyObject) {
        self.tryingToOpen = .Profile
        if !self.doesUserNeedAccountOrNickname() {
            self.resumeOpening()
        }
    }
    
    @IBAction func btnMessages(sender: AnyObject) {
        self.tryingToOpen = .Messages
        if !self.doesUserNeedAccountOrNickname() {
            self.resumeOpening()
        }
    }
    
    @IBAction func btnChat(sender: AnyObject) {
        self.tryingToOpen = .LiveChat
        if !self.doesUserNeedAccountOrNickname() {
            self.resumeOpening()
        }
    }
    
    @IBAction func near(sender: AnyObject) {
        self.tryingToOpen = .NearMe
        if !self.doesUserNeedAccountOrNickname() {
            self.resumeOpening()
        }
    }
    
    @IBAction func btnTourMap(sender: AnyObject) {
        self.tryingToOpen = .Map
        self.resumeOpening()
    }
    
    @IBAction func shop(sender: UIControl) {
        self.tryingToOpen = .Store
        if !self.doesUserNeedAccountOrNickname() {
            self.resumeOpening()
        }
    }
    
    @IBAction func support(sender: UIControl) {
        let alert = UIAlertController(title: "Support The Cadets", message: "Coming soon.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func openStore() {
        self.performSegueWithIdentifier("store", sender: self)
    }
    
    func openProfile() {
        self.performSegueWithIdentifier("profile", sender: self)
    }
    
    func openMessages() {
        privateChatSegue = true
        self.performSegueWithIdentifier("chat", sender: self)
    }
    
    func openChat() {
        privateChatSegue = false
        self.performSegueWithIdentifier("chat", sender: self)
    }
    
    func openNearMe() { //one extra step compared to the other open() functions to ensure location is enabled
        if self.doesUserHaveLocationServicesEnabled() {
            self.performSegueWithIdentifier("find", sender: self)
        }
    }
    
    func openMap() {
        self.performSegueWithIdentifier("tour", sender: self)
    }
    
    //MARK:-
    //MARK: Account Functions
    
    // Checks to see if user has a profile and nickname
    // If they need either, prompts the user
    // If they don't, returns false to the caller can resumeOpening()
    func doesUserNeedAccountOrNickname() -> Bool {
        if profileActive() {
            if !doesUserNeedNickname() {
                return false
            } else {
                signUpForView("nickname")
                return true
            }
        } else {
            signUpForView("account")
            return true
        }
    }
    
    // Called by doesUserNeedAccountOrNickname()
    // Do not call directly
    func profileActive() -> Bool {
        if PFUser.currentUser() != nil {
            return true
        } else {
            return false
        }
    }
    
    // Called by doesUserNeedAccountOrNickname()
    // Do not call directly
    func doesUserNeedNickname() -> Bool {
        if let user = PFUser.currentUser() {
            if let nickname = user["nickname"] as? String {
                if nickname.characters.count < 1 {
                    return true
                } else {
                    return false
                }
            } else {
                return true
            }
        }
        return false
    }
    
    func signUpForView(view: String) {
        if let signUpView = NSBundle.mainBundle().loadNibNamed("CreateAccount", owner: self, options: nil).first as? CreateAccount {
            signUpView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
            signUpView.setDelegate(self);
            signUpView.showView(view, inParent: self.navigationController!)
        }
    }
    
    // delegateCreateAccount in CreateAccount.h
    
    func accountCreated() {
        self.resumeOpening()
    }
    
    //MARK:-
    //MARK: Location Functions
    
    // Checks to see if user has allowed location services
    // If so, returns true
    // If not, prompts user
    // Before this is called, call doesUserNeedAccountOrNickname(), because we need an account to write geo to
    func doesUserHaveLocationServicesEnabled() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .AuthorizedAlways: return true
            case .AuthorizedWhenInUse: return true
            case .Denied:
                self.tellUserToEnableLocationForView()
                return false
            case .NotDetermined:
                self.askForLocationPermissionForView()
                return false
            case .Restricted:
                self.tellUserToEnableLocationForView()
                return false
            }
        } else {
            return false
        }
    }

    func askForLocationPermissionForView() {
        if let viewLoc = NSBundle.mainBundle().loadNibNamed("LocationServicesPermission", owner: self, options: nil).first as? LocationServicesPermission {
            viewLoc.showInParent(self.navigationController)
            viewLoc.setDelegate(self)
            viewLocationForDelegate = viewLoc
        }
    }
    
    func tellUserToEnableLocationForView() {
        if let viewLocation = NSBundle.mainBundle().loadNibNamed("LocationServicesDisabled", owner: self, options: nil).first as? LocationServicesDisabled {
            viewLocation.showInParent(self.navigationController)
        }
    }
    
    // deleateUserLocation in Server.swift
    // called from updateUserLocation()
    func userLocationUpdated(location: CLLocation) {
        viewLocationForDelegate.dismissView()
        self.resumeOpening()
    }
    
    // deleateUserLocation in Server.swift
    // called from updateUserLocation()
    func userLocationError() {
        viewLocationForDelegate.dismissView()
        let alert = UIAlertController(title: "Location Services", message: "Corpsboard could not update your location.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //TODO: Double check to make sure lazy inits aren't required on some of the properties
    
    //MARK:-
    //MARK: Helper Functions
    
    func resumeOpening() {
        switch tryingToOpen {
        case .Profile: self.openProfile()
        case .LiveChat: self.openChat()
        case .Map: self.openMap()
        case .Messages: self.openMessages()
        case .NearMe: self.openNearMe()
        case .Store: self.openStore()
        default: break
        }
    }
    
    func openShowAtIndex(indexPath: NSIndexPath, tableView: UITableView) {
        if tableView === self.tableLastShows {
            self.showToOpen = self.arrayOfShowsForTable1[indexPath.row]
            if self.showToOpen != nil {
                self.performSegueWithIdentifier("openShow", sender: self)
            }
        } else if tableView === self.tableNextShows {
            self.showToOpen = self.arrayOfShowsForTable2[indexPath.row]
            if self.showToOpen != nil {
                self.performSegueWithIdentifier("openShow", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "openShow" {
            let vc = segue.destinationViewController as! CBShowDetailsViewController
            vc.show = self.showToOpen
        } else if segue.identifier == "profile" {
            let vc = segue.destinationViewController as! CBUserProfileViewController
            vc.setUser(PFUser.currentUser())
        } else if segue.identifier == "chat" {
            let vc = segue.destinationViewController as! ChatRoomsTableViewController
            vc.isPrivate = privateChatSegue
        }
    }
    
    func makePrediction() {
        self.performSegueWithIdentifier("contest", sender: self)
    }
    
    func checkForNewVersion() {
        let releasedVersion = Server.sharedInstance.objAdmin?.releasedVersion
        if let info = NSBundle.mainBundle().infoDictionary {
            let userVersion = info["CFBundleShortVersionString"] as! String
            if releasedVersion != userVersion {
                self.newVersion()
            }
        }
    }
    
    func newVersion() {
        
    }
    
    func updateUserMessages() {
        self.setMsgBadge()
    }
    
    func setMsgBadge() {
        if Server.sharedInstance.numberOfMessages > 0 {
            self.badgeMessages.badgeText = "\(Server.sharedInstance.numberOfMessages)"
        } else {
            self.badgeMessages.badgeText = ""
        }
    }
    
    func setAdminBadge() {
        var num = 0
        num += (Server.sharedInstance.objAdmin?.feedback)!
        num += (Server.sharedInstance.objAdmin?.photos)!
        num += (Server.sharedInstance.objAdmin?.usersReported)!
        num += (Server.sharedInstance.objAdmin?.problems)!
        if num > 0 {
            self.badgeAdmin.badgeText = "\(num)"
        } else {
            self.badgeAdmin.badgeText = ""
        }
    }
}
