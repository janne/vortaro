//
//  Translation.swift
//  Vortaro
//
//  Created by Jan Andersson on 2015-12-28.
//  Copyright © 2015 Visuell Data. All rights reserved.
//

import Foundation

enum WordClass {
    case Phrase, Suffix, Prefix, Preposition, Pronoun, Numeral, Particle, Adverb, Verb, Noun, Adjective, Correlative, Other
}

class Translation : Hashable {
    var hashValue : Int { return eo.hashValue }
    var eo: String
    var ens: [String]
    var wordClass: WordClass?
    var parts: [String]?
    var base: String {
        return parts?.first ?? ""
    }
    let prepositions = ["al", "anstataŭ", "antaŭ", "apud", "cis", "ĉe", "ĉirkaŭ", "da", "de", "disde", "dum", "ekde", "ekster", "el", "en", "estiel", "far", "for", "graŭ", "ĝis", "inter", "je", "kiel", "kontraŭ", "krom", "kun", "laŭ", "malantaŭ", "malapud", "malgraŭ", "malsupre", "meze", "na", "per", "po", "por", "post", "preter", "pri", "pro", "proksime", "samkiel", "sen", "sob", "sub", "super", "sur", "tra", "trans"]
    let particles = ["ajn", "almenaŭ", "ankaŭ", "apenaŭ", "eĉ", "hoj", "ja", "jam", "jes", "kaj", "ke", "kvankam", "kvazaŭ", "malpli", "malplej", "mem", "nek", "nur", "ol", "plej", "pli", "plu", "se", "sed", "tamen", "tre", "tro", "tuj", "ĉar", "ĉi", "ĵus"]
    let adverbs = ["baldaŭ", "hieraŭ", "hodiaŭ", "morgaŭ", "nun", "postmorgaŭ", "preskaŭ"]
    let correlative_prefixes = ["ki", "ti", "i", "ĉi", "neni"]
    let correlative_suffixes = ["o", "u", "a", "e", "el", "al", "am", "om", "es"]
    var correlatives: [String] {
        var c = [String]()
        correlative_prefixes.forEach { p in
            correlative_suffixes.forEach { s in
                c.append(p + s)
            }
        }
        return c
    }

    init(eo: String, ens: [String]) {
        self.eo = eo
        self.ens = ens
    }

    func description() -> String {
        if wordClass == .None {
            analyze()
        }
        return inEnglish()
            + inEsperanto()
            + grammar()
            + links()
    }


    func inEsperanto() -> String {
        var s = eo
        if let p = parts {
            if p.count > 1 {
                s = p.joinWithSeparator(" + ")
            }
        }
        return "<h3>Esperantlingva</h3><p>\(s)</p>"
    }

    func inEnglish() -> String {
        let ens_list: String
        if ens.count > 1 {
            ens_list = "<ul>" + ens.map{ "<li>\($0)</li>" }.joinWithSeparator("") + "</ul>"
        } else {
            ens_list = "<p>\(ens.first ?? "")</p>"
        }
        return "<h3>Anglalingva</h3>"
            + ens_list
    }

    func grammar() -> String {
        var s = ""
        if let wc = translatedWordClass() {
            s += "<h3>Gramatiko</h3><p>Estas "
            var desc = [String]()
            if let p = parts {
                if p.contains("j") {
                    desc.append("plurala")
                }
                if p.contains("n") {
                    desc.append("akuzativa")
                }
            }
            s += desc.joinWithSeparator(", ") + " "
            s += wc + "</p>"
        }
        if let wc = wordClass {
            switch wc {
            case .Verb:
                s += "<p>\(verbTable())</p>"
            case .Noun:
                s += "<p>\(caseTable(base + "o"))</p>"
            case .Adjective:
                s += "<p>\(caseTable(base + "a"))</p>"
            case .Correlative:
                s += "<p>\(correlativeTable())</p>"
            case .Pronoun:
                s += "<p>\(pronounTable())</p>"
            default:
                false
            }
        }
        return s
    }

    func links() -> String {
        return "<h3>Retligiloj</h3>"
            + "<ul><li>"
            + "<a href='https://eo.m.wikipedia.org/wiki/\(eo)'>Vikipedio</a>"
            + "(<a href='https://en.m.wikipedia.org/wiki/\(ens.first)'>en</a>)"
            + "</li><li>"
            + "<a href='https://eo.m.wiktionary.org/wiki/\(eo)'>Vikivortaro</a>"
            + "(<a href='https://en.m.wiktionary.org/wiki/\(ens.first)'>en</a>)"
            + "</li><li>"
            + "<a href='https://translate.google.com/#eo/en/\(eo)'>Google Translate</a>"
            + "(<a href='https://translate.google.com/#en/eo/\(ens.first)'>en</a>)"
            + "</li></ul>"
    }

    func analyze() {
        if isPhrase() {
            wordClass = .Phrase
        } else if isSuffix() {
            wordClass = .Suffix
        } else if isPrefix() {
            wordClass = .Prefix
        } else if prepositions.contains(eo.lowercaseString) {
            wordClass = .Preposition
        } else if numerals().contains(eo.lowercaseString) {
            wordClass = .Numeral
        } else if particles.contains(eo.lowercaseString) {
            wordClass = .Particle
        } else if adverbs.contains(eo.lowercaseString) {
            wordClass = .Adverb
        } else if correlatives.contains(eo.lowercaseString) {
            wordClass = .Correlative
        } else if let parts = partsByPattern("^(mi|ni|vi|li|ŝi|ĝi|ili|oni|si|ci)(a?)(n?)$") {
            self.parts = parts
            wordClass = .Pronoun
        } else if let parts = partsByPattern("^(.*)(e)(n?)!?$") {
            wordClass = .Adverb
            self.parts = parts
        } else if let parts = partsByPattern("^(.*)(i|as|is|os|us|u)!?$") {
            wordClass = .Verb
            self.parts = parts
        } else if let parts = partsByPattern("^(.*)(o)(j?)(n?)!?$") {
            wordClass = .Noun
            self.parts = parts
        } else if let parts = partsByPattern("^(.*)(a)(j?)(n?)$") {
            wordClass = .Adjective
            self.parts = parts
        } else {
            wordClass = .Other
        }
    }

    func matches(pattern: String) -> NSTextCheckingResult? {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.CaseInsensitive])
        let matches = regex.matchesInString(eo, options: [], range: NSMakeRange(0, (eo as NSString).length))
        return matches.first
    }

    func partsByPattern(pattern: String) -> [String]? {
        if let matches = matches(pattern) {
            var parts = [String]()
            for var i = 1; i < matches.numberOfRanges; i++ {
                if let range = eo.rangeFromNSRange(matches.rangeAtIndex(i)) {
                    if !range.isEmpty {
                        parts.append(eo[range])
                    }
                }
            }
            return parts
        }
        return nil
    }

    func isPhrase() -> Bool {
        return matches(" ") != .None
    }

    func isSuffix() -> Bool {
        return matches("^-") != .None
    }

    func isPrefix() -> Bool {
        return matches("^[^-].*-$") != .None
    }

    func verbTable() -> String {
        return "<table>"
            + "<tr><th>Tempo</th><th>Vortformo</th><th>Aktiva Voĉo</th><th>Pasiva Voĉo</th></tr>"
            + "<tr><td><b>Prezenco</b></td><td>\(j(base + "as"))</td><td>\(j(base + "anta"))</td><td>\(j(base + "ata"))</td></tr>"
            + "<tr><td><b>Preterito</b></td><td>\(j(base + "is"))</td><td>\(j(base + "inta"))</td><td>\(j(base + "ita"))</td></tr>"
            + "<tr><td><b>Futuro</b></td><td>\(j(base + "os"))</td><td>\(j(base + "onta"))</td><td>\(j(base + "ota"))</td></tr>"
            + "<tr><td><b>Kondicionalo</b></td><td>\(j(base + "us"))</td><td>\(j(base + "unta"))</td><td>\(j(base + "uta"))</td></tr>"
            + "<tr><td><b>Imperativo</b></td><td>\(j(base + "u"))</td></tr>"
            + "</table>"
    }

    func j(word: String) -> String {
        if word == parts?.joinWithSeparator("") {
            return "<b><u>\(word)</u></b>"
        }
        return word
    }

    func caseTable(base: String) -> String {
        return "<table>"
            + "<tr><th>Kazo</th><th>Ununombro</th><th>Multenombro</th></tr>"
            + "<tr><td><b>Nominativo</b></td><td>\(j(base))</td><td>\(j(base + "j"))</td></tr>"
            + "<tr><td><b>Akuzativo</b></td><td>\(j(base + "n"))</td><td>\(j(base + "jn"))</td></tr>"
            + "</table>"
    }

    func pronounTable() -> String {
        return "<table>"
        + "<tr><th></th><th>Personaj</th><th>Posedaj</th></tr>"
        + "<tr><th>Nominativo</th><td>\(j(base))</td><td>\(j(base + "a"))</td></tr>"
        + "<tr><th>Akuzativo</th><td>\(j(base + "n"))</td><td>\(j(base + "an"))</td></tr>"
        + "</table>"
    }

    func correlativeTable() -> String {
        var result = "<table><tr><th></th>"
        for p in correlative_prefixes {
            result += "<th>\(p.uppercaseString)-</th>"
        }
        result += "</tr>"
        for s in correlative_suffixes {
            result += "<tr><td><b>-\(s.uppercaseString)</b></td>"
            for p in correlative_prefixes {
                if p + s == eo {
                    result += "<td><b><u>\(p + s)</u></b></td>"
                } else {
                    result += "<td>\(p + s)</td>"
                }
            }
            result += "</tr>"
        }
        result += "</table>"
        return result
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

    func translatedWordClass() -> String? {
        if let wc = wordClass {
            switch wc {
            case .Phrase: return "frazo"
            case .Suffix: return "sufikso"
            case .Prefix: return "prefikso"
            case .Preposition: return "prepozicio"
            case .Pronoun: return "pronomo"
            case .Numeral: return "numeralo"
            case .Particle: return "partiklo"
            case .Adverb: return "adverbo"
            case .Verb: return "verbo"
            case .Noun: return "substantivo"
            case .Adjective: return "adjektivo"
            case .Correlative: return "korelativo"
            case .Other: return .None
            }
        }
        return .None
    }
}

func ==(lhs: Translation, rhs: Translation) -> Bool {
    return lhs.hashValue == rhs.hashValue
}