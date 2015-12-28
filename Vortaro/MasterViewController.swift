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
    var dictEoEn = [String: String]()

    func readWordList() {
        let path = NSBundle.mainBundle().pathForResource("espdic", ofType: "txt")
        let espdic = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        let lines = espdic.componentsSeparatedByString("\n")
        
        for(var i = 0; i < lines.count; i++) {
            let words = lines[i].componentsSeparatedByString(":")
            if words.count > 1 {
                let eo = words[0].trim()
                let en = words[1].trim()
                eoWords = eoWords.stringByAppendingString("\(eo)\n")
                dictEoEn[eo] = en
                objects.append(Translation(eo: eo, en: en))
            }
        }
    }

    func search(searchText: String, scope: String) -> [Translation] {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: searchText, options: [.CaseInsensitive, .AnchorsMatchLines])
        } catch {
            return []
        }
        var filtered = [Translation]()
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
        return filtered
    }

    func filterContentForSearchText(searchText: String, scope: String = "Esperanto") {
        /*
        filteredObjects = objects.filter { object in
            switch scope {
            case "Esperanto":
                return object.eo.lowercaseString.containsString(searchText.lowercaseString)
            case "English":
                return object.en.lowercaseString.containsString(searchText.lowercaseString)
            case "Regex":
                return object.eo.rangeOfString(searchText, options: [.RegularExpressionSearch, .CaseInsensitiveSearch]) != nil
            default:
                return true
            }
        }
        */

        if (searchText as NSString).length > 1 {
            filteredObjects = search(searchText, scope: scope)
        } else {
            filteredObjects = objects
        }

        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        readWordList()

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar

        searchController.searchBar.scopeButtonTitles = ["Esperanto", "English", "Regex"]
        searchController.searchBar.delegate = self

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
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

    func insertNewObject(sender: AnyObject) {
        objects.insert(Translation(eo: "Bar", en: "Foo"), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
        if searchController.active && searchController.searchBar.text != "" {
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


    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
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
