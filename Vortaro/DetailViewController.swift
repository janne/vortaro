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
            self.configureView()
        }
    }

    func configureView() {
        if let detail = self.detailItem {
            if let view = self.webView {
                let lbl = "<body style=\"font-family: '-apple-system','HelveticaNeue'; font-size:18px;\">\(detail.description())</body>"
                view.loadHTMLString(lbl, baseURL: nil)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }
}

