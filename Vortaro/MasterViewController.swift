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
    var objects = [Translation]()
    var filteredObjects = [Translation]()
    var eoWords: NSString = ""
    var enWords: NSString = ""
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

    func eachMatch(pattern: String, text: NSString, fn: (String -> ())) {
        if let regex = buildRegexp(pattern) {
            let matches = regex.matchesInString(text as String, options: [], range: NSMakeRange(0, text.length))
            for match in matches.prefix(10000) {
                let range = text.lineRangeForRange(match.range)
                fn(text.substringWithRange(range).trim())
            }
        }
    }

    func searchEn(searchText: String) -> [Translation] {
        var filtered = [Translation]()
        eachMatch(searchText, text: enWords) { en in
            if let eos = self.enToEos[en] {
                for eo in eos {
                    filtered.append(Translation(eo: eo, ens: self.eoToEns[eo] ?? []))
                }
            }
        }
        return filtered
    }

    func searchEo(searchText: String) -> [Translation] {
        var filtered = [Translation]()
        eachMatch(searchText, text: eoWords) { eo in
            if let ens = self.eoToEns[eo] {
                filtered.append(Translation(eo: eo, ens: ens))
            }
        }
        return filtered
    }

    func searchBoth(searchText: String) -> [Translation] {
        let filtered = Set(searchEo(searchText) + searchEn(searchText))
        return filtered.sort { $0.eo.lowercaseString < $1.eo.lowercaseString }
    }

    func filterContentForSearchText(searchText: String, scope: String = "Esperanto") {
        dispatch_async(queue) {
            if searchText == "" {
                self.filteredObjects = self.objects
            } else if scope == "Esperanto" {
                self.filteredObjects = self.searchEo(searchText)
            } else if scope == "English" {
                self.filteredObjects = self.searchEn(searchText)
            } else {
                self.filteredObjects = self.searchBoth(searchText)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        eoWords = readText("eos")
        eoToEns = readJSON("eo_to_ens")
        for eo in eoWords.componentsSeparatedByString("\n") {
            objects.append(Translation(eo: eo, ens: eoToEns[eo] ?? []))
        }

        dispatch_async(queue) {
            self.enWords = self.readText("ens")
            self.enToEos = self.readJSON("en_to_eos")
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        searchController.searchBar.scopeButtonTitles = ["Esperanto", "English", "Both"]
        searchController.searchBar.delegate = self

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = translations()[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.title = object.eo
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func translations() -> [Translation] {
        if searchController.active && searchController.searchBar.text! != "" {
            return filteredObjects
        }
        return objects
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return translations().count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if indexPath.row < translations().count {
            let object = translations()[indexPath.row]
            cell.textLabel?.text = object.eo
            cell.detailTextLabel?.text = object.ens.joinWithSeparator(", ")
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
