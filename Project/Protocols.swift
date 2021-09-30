//
//  Protocols.swift
//  Project
//
//  Created by Dorian Bizgan on 7/8/20.
//  Copyright © 2020 Dorian Bizgan. All rights reserved.
//

import Foundation
import UIKit

protocol DocumentUpdater {
    func addDocument(text:String, documentTitle:String)
    func updateDocument(text:String, documentTitle:String, documentIndex:Int)
}
