//
//  MasterViewController.swift
//  Vortaro
//
//  Created by Jan Andersson on 2015-12-28.
//  Copyright © 2015 Visuell Data. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    let searchController = UISearchController(searchResultsController: nil)
    var fromLanguage = "Esperanto"
    var eoWords = [String]()
    var enWords = [String]()
    var words = [String]()
    var eoText: NSString = ""
    var enText: NSString = ""
    var enToEos = [String: [String]]()
    var eoToEns = [String: [String]]()
    let queue = dispatch_queue_create("serial-worker", DISPATCH_QUEUE_SERIAL)

    func readText(file: String, ofType type: String = "txt") -> String {
        let path = NSBundle.mainBundle().pathForResource(file, ofType: type)
        return try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
    }

    func readJSON(file: String, ofType type: String = "json") -> [String: [String]] {
        if let jsonList = NSBundle.mainBundle().pathForResource(file, ofType: "json") {
            if let theList = NSData(contentsOfFile: jsonList) {
                let listStream = NSInputStream(data: theList)
                listStream.open()
                do {
                    return try NSJSONSerialization.JSONObjectWithStream(listStream, options: [.AllowFragments]) as! [String : [String]]
                } catch {
                    return [:]
                }
            }
        }
        return [:]
    }


    func buildRegexp(var pattern: String) -> NSRegularExpression? {
        let replacements = [
            "c": "ĉ",
            "g": "ĝ",
            "h": "ĥ",
            "j": "ĵ",
            "s": "ŝ",
            "u": "ŭ",
        ]
        for (k, v) in replacements {
            pattern = pattern.stringByReplacingOccurrencesOfString(k, withString: "[\(k)\(v)]")
            pattern = pattern.stringByReplacingOccurrencesOfString(k.uppercaseString, withString: "[\(k.uppercaseString)\(v.uppercaseString)]")
        }
        do {
            return try NSRegularExpression(pattern: "^\(pattern)", options: [.CaseInsensitive, .AnchorsMatchLines])
        } catch {
            return nil
        }
    }

    func findMatches(pattern: String, text: NSString) -> [String] {
        if let regex = buildRegexp(pattern) {
            let matches = regex.matchesInString(text as String, options: [], range: NSMakeRange(0, text.length))
            return matches.prefix(10000).map { match in
                let range = text.lineRangeForRange(match.range)
                return text.substringWithRange(range).trim()
            }
        }
        return []
    }

    func filterContentForSearchText(searchText: String, scope: String = "Esperanto") {
        dispatch_async(queue) {
            self.fromLanguage = scope
            var text: NSString
            var words: [String]
            if scope == "Esperanto" {
                text = self.eoText
                words = self.eoWords
            } else {
                text = self.enText
                words = self.enWords
            }

            if searchText == "" {
                self.words = words
            } else {
                self.words = self.findMatches(searchText, text: text)
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        eoText = readText("eos")
        eoToEns = readJSON("eo_to_ens")
        eoWords = eoText.componentsSeparatedByString("\n")

        dispatch_async(queue) {
            self.enText = self.readText("ens")
            self.enToEos = self.readJSON("en_to_eos")
            self.enWords = self.enText.componentsSeparatedByString("\n")
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        searchController.searchBar.scopeButtonTitles = ["Esperanto", "English"]
        searchController.searchBar.delegate = self
        searchController.searchBar.becomeFirstResponder()

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let word = words[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                let translation = Translation(fromLanguage: fromLanguage, fromWord: word, toWords: toWords(word))
                controller.eoToEns = eoToEns
                controller.detailItem = translation
                controller.title = word
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    func toWords(word: String) -> [String] {
        if fromLanguage == "Esperanto" {
            return eoToEns[word] ?? []
        } else {
            return enToEos[word] ?? []
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if indexPath.row < words.count {
            let fromWord = words[indexPath.row]
            cell.textLabel?.text = fromWord
            cell.detailTextLabel?.text = toWords(fromWord).joinWithSeparator(", ")
        }
        return cell
    }
}

extension MasterViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
    }
}

extension MasterViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}
