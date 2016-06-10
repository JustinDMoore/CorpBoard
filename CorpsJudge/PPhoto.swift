//
//  PPhoto.swift
//  CorpBoard
//
//  Created by Justin Moore on 5/8/16.
//  Copyright © 2016 Justin Moore. All rights reserved.
//

import Foundation

class PPhoto: PFObject, PFSubclassing {

    @NSManaged var userSubmitted: Bool
    @NSManaged var name: String
    @NSManaged var photo: PFFile
    @NSManaged var approved: Bool
    @NSManaged var type: String
    @NSManaged var isPublic: Bool
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    static func parseClassName() -> String {
        return "Photos"
    }
}
