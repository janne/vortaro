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

    func ens() -> [String] {
        if en[en.startIndex] == "(" {
            return [en]
        } else {
            return en.componentsSeparatedByString(",").map { $0.trim() }
        }
    }

    func match(pattern: String) -> Range<String.Index>? {
        return eo.rangeOfString(pattern, options: [.RegularExpressionSearch, .CaseInsensitiveSearch])
    }

    func nounBase() -> String? {
        if let range = match("oj?n?!?$") {
            return eo[eo.startIndex..<range.startIndex]
        }
        return .None
    }

    func verbBase() -> String? {
        if let range = match("(i|as|u)!?$") {
            return eo[eo.startIndex..<range.startIndex]
        }
        return .None
    }

    func adjectiveBase() -> String? {
        if let range = match("aj?n?$") {
            let root = eo[eo.startIndex..<range.startIndex]
            if root.characters.count > 0 {
                return eo[eo.startIndex..<range.startIndex]
            } else {
                return .None
            }
        }
        return .None
    }

    func isAdverb() -> Bool {
        return match("en?!?$") != .None || adverbs().contains(eo.lowercaseString)
    }

    func isExpression() -> Bool {
        return match(" ") != .None
    }

    func isSuffix() -> Bool {
        return match("^-") != .None
    }

    func isPrefix() -> Bool {
        return match("^[^-].*-$") != .None
    }

    func verbTable(root: String) -> String {
        return "<table>"
            + "<tr><th>Tempo</th><th>Vortformo</th><th>Aktiva Voĉo</th><th>Pasiva Voĉo</th></tr>"
            + "<tr><td><b>Prezenco</b></td><td>\(root)as</td><td>\(root)anta</td><td>\(root)ata</td></tr>"
            + "<tr><td><b>Preterito</b></td><td>\(root)is</td><td>\(root)inta</td><td>\(root)ita</td></tr>"
            + "<tr><td><b>Futuro</b></td><td>\(root)os</td><td>\(root)onta</td><td>\(root)ota</td></tr>"
            + "<tr><td><b>Kondicionalo</b></td><td>\(root)us</td><td>\(root)unta</td><td>\(root)uta</td></tr>"
            + "<tr><td><b>Imperativo</b></td><td>\(root)u</td></tr>"
            + "</table>"
    }

    func caseTable(root: String, type: String) -> String {
        return "<table>"
            + "<tr><th>Kazo</th><th>Ununombro</th><th>Multenombro</th></tr>"
            + "<tr><td><b>Nominativo</b></td><td>\(root)\(type)</td><td>\(root)\(type)j</td></tr>"
            + "<tr><td><b>Akuzativo</b></td><td>\(root)\(type)n</td><td>\(root)\(type)jn</td></tr>"
            + "</table>"
    }

    func prepositions() -> [String] {
        return ["al", "anstataŭ", "antaŭ", "apud", "cis", "ĉe", "ĉirkaŭ", "da", "de", "disde", "dum", "ekde", "ekster", "el", "en", "estiel", "far", "for", "graŭ", "ĝis", "inter", "je", "kiel", "kontraŭ", "krom", "kun", "laŭ", "malantaŭ", "malapud", "malgraŭ", "malsupre", "meze", "na", "per", "po", "por", "post", "preter", "pri", "pro", "proksime", "samkiel", "sen", "sob", "sub", "super", "sur", "tra", "trans"]

    }

    func adverbs() -> [String] {
        return ["baldaŭ", "hieraŭ", "hodiaŭ", "morgaŭ", "nun", "postmorgaŭ", "preskaŭ"]
    }

    func pronomes() -> [String] {
        return ["ambaŭ", "ili", "li", "mi", "ni", "oni", "si", "vi", "ĝi", "ŝi"]
    }

    func numerals() -> [String] {
        var results = ["nul", "unu"]
        let nums = ["du", "tri", "kvar", "kvin", "ses", "sep", "ok", "naŭ"]
        let mults = ["dek", "cent", "mil"]
        results += nums
        results += mults
        for prefix in nums {
            for suffix in mults {
                results.append(prefix + suffix)
            }
        }
        return results
    }

    func particles() -> [String] {
        return ["ajn", "almenaŭ", "ankaŭ", "apenaŭ", "eĉ", "hoj", "ja", "jam", "jes", "kaj", "ke", "kvankam", "kvazaŭ", "malpli", "malplej", "mem", "nek", "nur", "ol", "plej", "pli", "plu", "se", "sed", "tamen", "tre", "tro", "tuj", "ĉar", "ĉi", "ĵus"]

    }

    func etymology() -> String {
        if isExpression() {
            return ""
        }
        if isSuffix() {
            return "<h3>Suffix</h3>"
        } else if isPrefix() {
            return "<h3>Prefix</h3>"
        } else if prepositions().contains(eo.lowercaseString) {
            return "<h3>Preposition</h3>"
        } else if pronomes().contains(eo.lowercaseString) {
            return "<h3>Pronomo</h3>"
        } else if numerals().contains(eo.lowercaseString) {
            return "<h3>Numeralo</h3>"
        } else if particles().contains(eo.lowercaseString) {
            return "<h3>Particle</h3>"
        } else if isAdverb() {
            return "<h3>Adverb</h3>"
        } else if let base = verbBase() {
            return "<h3>Verb</h3>" + verbTable(base)
        } else if let base = nounBase() {
            return "<h3>Substantivo</h3>" + caseTable(base, type: "o")
        } else if let base = adjectiveBase() {
            return "<h3>Adjektivo</h3>" + caseTable(base, type: "a")
        } else {
            return ""
        }
    }
}