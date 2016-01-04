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
                let ens_list: String
                if detail.ens().count > 1 {
                ens_list = "<ul>" + detail.ens().map{ "<li>\($0)</li>" }.joinWithSeparator("") + "</ul>"
                } else {
                    ens_list = "<p>\(detail.en)</p>"
                }
                let lbl = ""
                    + "<body style=\"font-family: '-apple-system','HelveticaNeue'; font-size:18px;\">"
                    + "<h3>Esperantlingva</h3><p>\(detail.eo)</p><h3>Anglalingva</h3>"
                    + ens_list
                    + detail.etymology()
                    + "<h3>Retligoj</h3>"
                    + "<ul><li>"
                    + "<a href='https://eo.m.wikipedia.org/wiki/\(detail.eo)'>Vikipedio</a>"
                    + "(<a href='https://en.m.wikipedia.org/wiki/\(detail.ens()[0])'>en</a>)"
                    + "</li><li>"
                    + "<a href='https://eo.m.wiktionary.org/wiki/\(detail.eo)'>Vikivortaro</a>"
                    + "(<a href='https://en.m.wiktionary.org/wiki/\(detail.ens()[0])'>en</a>)"
                    + "</li></ul></body>"
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

