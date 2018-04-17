//
//  Vote+CoreDataProperties.swift
//  
//
//  Created by Micky on 2/10/17.
//
//

import Foundation
import CoreData


extension Vote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vote> {
        return NSFetchRequest<Vote>(entityName: "Vote");
    }

    @NSManaged public var downVoted: Bool
    @NSManaged public var trackName: String?
    @NSManaged public var upVoted: Bool
    @NSManaged public var venueId: String?

}
