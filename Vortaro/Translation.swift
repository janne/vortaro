//
//  Translation.swift
//  Vortaro
//
//  Created by Jan Andersson on 2015-12-28.
//  Copyright © 2015 Visuell Data. All rights reserved.
//

import Foundation

enum WordClass {
    case Phrase, Suffix, Prefix, Preposition, Pronoun, Numeral, Particle, Adverb, Verb, Noun, Adjective, Other
}

typealias GrammarResult = (String, [String])

class Translation {
    var eo: String
    var en: String
    var wordClass: WordClass?
    var base: String?
    var parts: [String]?

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
                s = p.joinWithSeparator("/")
            }
        }
        return "<h3>Esperantlingva</h3><p>\(s)</p>"
    }

    func inEnglish() -> String {
        let ens_list: String
        if ens().count > 1 {
            ens_list = "<ul>" + ens().map{ "<li>\($0)</li>" }.joinWithSeparator("") + "</ul>"
        } else {
            ens_list = "<p>\(en)</p>"
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
            if let b = base {
                switch wc {
                case .Verb:
                    s += "<p>\(verbTable(b + "i"))</p>"
                case .Noun:
                    s += "<p>\(caseTable(b + "o"))</p>"
                case .Adjective:
                    s += "<p>\(caseTable(b + "a"))</p>"
                default:
                    false
                }
            }
        }
        return s
    }

    func links() -> String {
        return "<h3>Retligoj</h3>"
            + "<ul><li>"
            + "<a href='https://eo.m.wikipedia.org/wiki/\(eo)'>Vikipedio</a>"
            + "(<a href='https://en.m.wikipedia.org/wiki/\(ens()[0])'>en</a>)"
            + "</li><li>"
            + "<a href='https://eo.m.wiktionary.org/wiki/\(eo)'>Vikivortaro</a>"
            + "(<a href='https://en.m.wiktionary.org/wiki/\(ens()[0])'>en</a>)"
            + "</li><li>"
            + "<a href='https://translate.google.com/#eo/en/\(eo)'>Google Translate</a>"
            + "(<a href='https://translate.google.com/#en/eo/\(ens()[0])'>en</a>)"
            + "</li></ul>"
    }

    func analyze() {
        if isPhrase() {
            wordClass = .Phrase
        } else if isSuffix() {
            wordClass = .Suffix
        } else if isPrefix() {
            wordClass = .Prefix
        } else if prepositions().contains(eo.lowercaseString) {
            wordClass = .Preposition
        } else if pronouns().contains(eo.lowercaseString) {
            wordClass = .Pronoun
        } else if numerals().contains(eo.lowercaseString) {
            wordClass = .Numeral
        } else if particles().contains(eo.lowercaseString) {
            wordClass = .Particle
        } else if let (base, parts) = adverbParts() {
            wordClass = .Adverb
            self.base = base
            self.parts = parts
        } else if let (base, parts) = verbParts() {
            wordClass = .Verb
            self.base = base
            self.parts = parts
        } else if let (base, parts) = nounParts() {
            wordClass = .Noun
            self.base = base
            self.parts = parts
        } else if let (base, parts) = adjectiveParts() {
            wordClass = .Adjective
            self.base = base
            self.parts = parts
        } else {
            wordClass = .Other
        }
    }

    func match(pattern: String) -> Range<String.Index>? {
        return eo.rangeOfString(pattern, options: [.RegularExpressionSearch, .CaseInsensitiveSearch])
    }

    func nounParts() -> GrammarResult? {
        if let range = match("oj?n?!?$") {
            let base = eo[eo.startIndex..<range.startIndex]
            var parts = [base]
            for char in eo[range.startIndex..<eo.endIndex].characters {
                parts.append(String(char))
            }
            return (base, parts)
        }
        return .None
    }

    func verbParts() -> GrammarResult? {
        if let range = match("(i|as|u)!?$") {
            let base = eo[eo.startIndex..<range.startIndex]
            var parts = [base]
            for char in eo[range.startIndex..<eo.endIndex].characters {
                parts.append(String(char))
            }
            return (base, parts)
        }
        return .None
    }

    func adjectiveParts() -> GrammarResult? {
        if let range = match("aj?n?$") {
            let base = eo[eo.startIndex..<range.startIndex]
            if base.characters.count > 0 {
                var parts = [base]
                for char in eo[range.startIndex..<eo.endIndex].characters {
                    parts.append(String(char))
                }
                return (base, parts)
            } else {
                return .None
            }
        }
        return .None
    }

    func adverbParts() -> GrammarResult? {
        if adverbs().contains(eo.lowercaseString) {
            return (eo, [eo])
        }
        if let range = match("en?!?$") {
            let base = eo[eo.startIndex..<range.startIndex]
            var parts = [base]
            for char in eo[range.startIndex..<eo.endIndex].characters {
                parts.append(String(char))
            }
            return (base, parts)
        }
        return .None
    }

    func isPhrase() -> Bool {
        return match(" ") != .None
    }

    func isSuffix() -> Bool {
        return match("^-") != .None
    }

    func isPrefix() -> Bool {
        return match("^[^-].*-$") != .None
    }

    func verbTable(base: String) -> String {
        return "<table>"
            + "<tr><th>Tempo</th><th>Vortformo</th><th>Aktiva Voĉo</th><th>Pasiva Voĉo</th></tr>"
            + "<tr><td><b>Prezenco</b></td><td>\(base)as</td><td>\(base)anta</td><td>\(base)ata</td></tr>"
            + "<tr><td><b>Preterito</b></td><td>\(base)is</td><td>\(base)inta</td><td>\(base)ita</td></tr>"
            + "<tr><td><b>Futuro</b></td><td>\(base)os</td><td>\(base)onta</td><td>\(base)ota</td></tr>"
            + "<tr><td><b>Kondicionalo</b></td><td>\(base)us</td><td>\(base)unta</td><td>\(base)uta</td></tr>"
            + "<tr><td><b>Imperativo</b></td><td>\(base)u</td></tr>"
            + "</table>"
    }

    func caseTable(base: String) -> String {
        return "<table>"
            + "<tr><th>Kazo</th><th>Ununombro</th><th>Multenombro</th></tr>"
            + "<tr><td><b>Nominativo</b></td><td>\(base)</td><td>\(base)j</td></tr>"
            + "<tr><td><b>Akuzativo</b></td><td>\(base)n</td><td>\(base)jn</td></tr>"
            + "</table>"
    }

    func prepositions() -> [String] {
        return ["al", "anstataŭ", "antaŭ", "apud", "cis", "ĉe", "ĉirkaŭ", "da", "de", "disde", "dum", "ekde", "ekster", "el", "en", "estiel", "far", "for", "graŭ", "ĝis", "inter", "je", "kiel", "kontraŭ", "krom", "kun", "laŭ", "malantaŭ", "malapud", "malgraŭ", "malsupre", "meze", "na", "per", "po", "por", "post", "preter", "pri", "pro", "proksime", "samkiel", "sen", "sob", "sub", "super", "sur", "tra", "trans"]

    }

    func adverbs() -> [String] {
        return ["baldaŭ", "hieraŭ", "hodiaŭ", "morgaŭ", "nun", "postmorgaŭ", "preskaŭ"]
    }

    func pronouns() -> [String] {
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
            case .Other: return .None
            }
        }
        return .None
    }
}