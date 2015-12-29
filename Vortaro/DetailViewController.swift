//
//  DetailViewController.swift
//  Vortaro
//
//  Created by Jan Andersson on 2015-12-28.
//  Copyright © 2015 Visuell Data. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!

    var detailItem: Translation? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let view = self.webView {
                var lbl = "" +
                "<body style=\"font-family: '-apple-system','HelveticaNeue'; font-size:18px;\">" +
                "<h3>Esperanto</h3><p>\(detail.eo)</p><h3>English</h3>"
                for word in detail.ens() {
                    lbl = lbl + "<p>\(word)</p>"
                }
                lbl = lbl + "<p><a href='https://eo.m.wikipedia.org/wiki/\(detail.eo)'>Vikipedio</a></p>"
                lbl = lbl + "<p><a href='https://eo.m.wiktionary.org/wiki/\(detail.eo)'>Vikivortaro</a></p>"
                lbl = lbl + "</body>"
                view.loadHTMLString(lbl, baseURL: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

