//
//  DetailViewController.swift
//  Vortaro
//
//  Created by Jan Andersson on 2015-12-28.
//  Copyright © 2015 Visuell Data. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UIWebViewDelegate {
    @IBOutlet weak var webView: UIWebView!
    var eoToEns = [String: [String]]()

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

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked {
            if let url = request.URL {
                if let _ = String(url).rangeOfString("^vortaro:", options: .RegularExpressionSearch) {
                    if let eo = String(url).componentsSeparatedByString(":")[1].stringByRemovingPercentEncoding {
                        if let ens = eoToEns[eo] {
                            title = eo
                            detailItem = Translation(fromLanguage: "Esperanto", fromWord: eo, toWords: ens)
                        }
                    }
                } else {
                    UIApplication.sharedApplication().openURL(url)
                }
                return false
            }
        }
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        self.configureView()
    }
}
