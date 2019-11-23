//
//  Double.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

extension Double {
    // Rounds the double to decimal places value
    
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
