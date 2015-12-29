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
    var dictEoEn = [String: String]()
    var dictEnEo = [String: [String]]()

    func readFile(file: String, ofType type: String = "txt") -> String {
        let path = NSBundle.mainBundle().pathForResource(file, ofType: type)
        return try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
    }

    func readWordList() {
        var eoWordsSet = Set<String>()
        var enWordsSet = Set<String>()
        for line in readFile("espdic").componentsSeparatedByString("\n") {
            let words = line.componentsSeparatedByString(":")
            if words.count > 1 {
                let eo = words[0].trim()
                let en = words[1].trim()
                let translation = Translation(eo: eo, en: en)
                dictEoEn[eo] = en
                for word in translation.ens() {
                    var eos = dictEnEo[word] ?? []
                    if !eos.contains(eo) {
                        eos.append(eo)
                    }
                    dictEnEo[word] = eos
                    enWordsSet.insert(word)
                }
                eoWordsSet.insert(eo)
                objects.append(translation)
            }
        }
        eoWords = eoWordsSet.joinWithSeparator("\n")
        enWords = enWordsSet.joinWithSeparator("\n")
    }

    func buildRegexp(pattern: String) -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern, options: [.CaseInsensitive, .AnchorsMatchLines])
        } catch {
            return nil
        }
    }

    func searchEn(searchText: String) -> [Translation] {
        var filtered = [Translation]()
        if let regex = buildRegexp(searchText) {
            var range = NSMakeRange(0, 0)
            let matches = regex.matchesInString(enWords as String, options: [], range: NSMakeRange(0, enWords.length))
            for match in matches {
                if match.range.location > NSMaxRange(range) {
                    range = enWords.lineRangeForRange(match.range)
                    let en = enWords.substringWithRange(range).trim()
                    if let eos = dictEnEo[en] {
                        for eo in eos {
                            if let n = dictEoEn[eo] {
                                filtered.append(Translation(eo: eo, en: n))
                            }
                        }
                    }
                }
            }
        }
        return filtered
    }

    func searchEo(searchText: String) -> [Translation] {
        var filtered = [Translation]()
        if let regex = buildRegexp(searchText) {
            var range = NSMakeRange(0, 0)
            let matches = regex.matchesInString(eoWords as String, options: [], range: NSMakeRange(0, eoWords.length))
            for match in matches {
                if match.range.location > NSMaxRange(range) {
                    range = eoWords.lineRangeForRange(match.range)
                    let eo = eoWords.substringWithRange(range).trim()
                    if let en = dictEoEn[eo] {
                        filtered.append(Translation(eo: eo, en: en))
                    }
                }
            }
        }
        return filtered
    }

    func filterContentForSearchText(searchText: String, scope: String = "Esperanto") {
        if (searchText as NSString).length <= 1 {
            filteredObjects = objects
        } else if scope == "Esperanto" {
            filteredObjects = searchEo(searchText)
        } else {
            filteredObjects = searchEn(searchText)
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        readWordList()

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        searchController.searchBar.scopeButtonTitles = ["Esperanto", "English"]
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
        if searchController.active && (searchController.searchBar.text! as NSString).length > 1 {
            return filteredObjects
        }
        return objects
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return translations().count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let object = translations()[indexPath.row]
        cell.textLabel?.text = object.eo
        cell.detailTextLabel?.text = object.en
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
