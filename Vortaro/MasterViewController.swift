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

    func readWordList() {
        let path = NSBundle.mainBundle().pathForResource("espdic", ofType: "txt")
        let dict = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        let lines = dict.componentsSeparatedByString("\n")
        
        for(var i = 0; i < lines.count; i++) {
            let words = lines[i].componentsSeparatedByString(":")
            if words.count > 1 {
                objects.append(Translation(eo: words[0].trim(), en: words[1].trim()))
            }
        }
    }

    func isSearching() -> Bool {
        return searchController.active && searchController.searchBar.text != ""
    }

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredObjects = objects.filter { object in
            let matchesEo = object.eo.lowercaseString.containsString(searchText.lowercaseString)
            let matchesEn = object.en.lowercaseString.containsString(searchText.lowercaseString)
            switch scope {
            case "English":
                return matchesEn
            case "Esperanto":
                return matchesEo
            default:
                return matchesEn || matchesEo
            }
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

        searchController.searchBar.scopeButtonTitles = ["All", "Esperanto", "English"]
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
                var object: Translation
                if isSearching() {
                    object = filteredObjects[indexPath.row]
                } else {
                    object = objects[indexPath.row]
                }
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

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching() {
            return filteredObjects.count
        }
        return objects.count

    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let object: Translation
        if isSearching() {
            object = filteredObjects[indexPath.row]
        } else {
            object = objects[indexPath.row]
        }
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
