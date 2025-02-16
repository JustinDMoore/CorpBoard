//
//  PickAStadium.swift
//  CorpBoard
//
//  Created by Justin Moore on 6/14/16.
//  Copyright © 2016 Justin Moore. All rights reserved.
//

import UIKit
import CoreLocation

class PickAStadium: UIView, UITableViewDelegate, UITableViewDataSource {


    @IBOutlet weak var txtFacility: UITextField!
    @IBOutlet weak var txtStadium: UITextField!
    @IBOutlet weak var txtAddress: UITextField!
    @IBOutlet weak var txtCity: UITextField!
    @IBOutlet weak var txtState: UITextField!
    @IBOutlet weak var txtZip: UITextField!
    @IBOutlet weak var txtLat: UITextField!
    @IBOutlet weak var txtLong: UITextField!
    @IBOutlet weak var tableStadiums: UITableView!
    @IBOutlet weak var btnSAve: UIButton!
    
    var show = PShow()
    var arrayOfStadiums = [PStadium]()
    
    
    func showInParent(parent: UINavigationController, forShow: PFObject) {
        
        self.frame = CGRectMake(0, 0, parent.view.frame.size.width, parent.view.frame.size.height)
        parent.view.addSubview(self)
        self.center = parent.view.center
        self.tableStadiums.dataSource = self
        self.tableStadiums.delegate = self
        show = forShow as! PShow
        getNearbyStadiums()
    }
    
    func getNearbyStadiums() {
        
        arrayOfStadiums = [PStadium]()
        
        let query = PFQuery(className: PStadium.parseClassName())
        query.limit = 1000
        query.whereKey("coordinates", nearGeoPoint: show.coordinates!, withinMiles: 50)
        query.findObjectsInBackgroundWithBlock { (stadiums: [PFObject]?, err: NSError?) in
            if stadiums != nil {
                self.arrayOfStadiums = stadiums as! [PStadium]
                self.tableStadiums.reloadData()
            }
        }
        
    
    
    
        
//        let state = String(show.showLocation.characters.suffix(2))
//        let query = PFQuery(className: PStadium.parseClassName())
//        query.whereKey("state", equalTo: state)
//        query.orderByDescending("city")
//        query.findObjectsInBackgroundWithBlock { (stadiums: [PFObject]?, err: NSError?) in
//            if stadiums != nil {
//                self.arrayOfStadiums = stadiums as! [PStadium]
//                self.tableStadiums.reloadData()
//            }
//        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfStadiums.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "cell")
        let stadium = arrayOfStadiums[indexPath.row]
        cell.textLabel!.text = "\(stadium.facility) - \(stadium.name)"
        cell.detailTextLabel!.text = "\(stadium.city) - \(stadium.address)"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let stadium = arrayOfStadiums[indexPath.row]
        show.stadium = stadium
        show.saveInBackground()
        self.removeFromSuperview()
    }
    
    
    @IBAction func save(sender: UIButton) {
        saveNewStadium()
    }
    
    func saveNewStadium() {
        let stadium = PStadium()
        stadium.facility = txtFacility.text!
        stadium.name = txtStadium.text!
        stadium.address = txtAddress.text!
        stadium.city = txtCity.text
        stadium.state = txtState.text
        stadium.zip = txtZip.text
        stadium.coordinates = PFGeoPoint(latitude: Double(txtLat.text!)!, longitude: Double(txtLong.text!)!)
        stadium.saveInBackgroundWithBlock { (success: Bool, err: NSError?) in
            if (success) {
                self.show.stadium = stadium
                self.show.saveInBackground()
                self.removeFromSuperview()
            } else {
                print("ERROR SAVING STADIUM")
            }
        }
    }
    
    
    @IBAction func cancel(sender: AnyObject) {
        self.removeFromSuperview()
    }
}
