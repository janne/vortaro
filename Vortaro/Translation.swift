//
//  Translation.swift
//  Vortaro
//
//  Created by Jan Andersson on 2015-12-28.
//  Copyright © 2015 Visuell Data. All rights reserved.
//

import Foundation

class Translation {
    var eo: String
    var en: String

    init(eo: String, en: String) {
        self.eo = eo
        self.en = en
    }

    var description: String {
        return "\(eo): \(en)"
    }

    func ens() -> [String] {
        return en.componentsSeparatedByString(",").map { $0.trim() }
    }
}