//
//  RStudioServerSessionWebViewController.swift
//  wktest
//
//  Created by hrbrmstr on 9/9/19.
//  Copyright © 2019 Bob Rudis. All rights reserved.
//

import Cocoa
import WebKit

class RstudioServerSessionWebViewController: NSViewController, NSWindowDelegate {

  var webView: WKWebView!
  var popupWebView: WKWebView?
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    setupWebView()
  }
  
  func setupWebView() {
    
    let preferences = WKPreferences()
    preferences.javaScriptEnabled = true
    preferences.javaScriptCanOpenWindowsAutomatically = true
    
    let configuration = WKWebViewConfiguration()
    configuration.preferences = preferences
    
    webView = WKWebView(frame: view.bounds, configuration: configuration)
    webView.autoresizingMask = [.width, .height]
    webView.uiDelegate = self
    webView.navigationDelegate = self
    
    view.addSubview(webView)
    
  }
  
  func loadWebView(urlIn: String) {
    
    if let url = URL(string: urlIn) {
      let urlRequest = URLRequest(url: url)
      webView.load(urlRequest)
    }
    
  }
    
}

extension RstudioServerSessionWebViewController: WKUIDelegate {

  func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {

    let openPanel = NSOpenPanel()
    
    openPanel.canChooseFiles = true
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false
    openPanel.canCreateDirectories = false
    openPanel.beginSheetModal(for:self.view.window!) { (response) in
      if (response == NSApplication.ModalResponse.OK) {
        completionHandler([openPanel.url!])
      } else {
        completionHandler(nil)
      }
      openPanel.close()
    }
    
  }
  
  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    
    if navigationAction.targetFrame == nil {
      
      let u = URL(string: navigationAction.request.url!.absoluteString)!
      
      if ((u.urlComponents?.path.starts(with: "/export/")) != nil) {
                
        let exportWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "exportPopupPanel") as! ExportWebViewController
        
        let exportWV = (exportWindowController.contentViewController as! exportPopupViewController)

        exportWV.view.window?.title = navigationAction.request.url!.absoluteString
        
        exportWV.setupWebView(configuration: configuration)
                
        exportWV.loadWebView(urlIn: "")
                
        let urlPath = navigationAction.request.url!.absoluteString
                
        // Check for "/export/"
        // If export, then get bring up a Save Panel and then download the file to that location

        if let url = URL(string: urlPath) {
                    
          if (url.path.starts(with: "/export")) {
                        
            let savePanel = NSSavePanel()
            
            savePanel.canCreateDirectories = true
            savePanel.nameFieldStringValue = url.queryParameters["name"]!
            savePanel.beginSheetModal(for:self.view.window!) { (response) in
              if (response == NSApplication.ModalResponse.OK) {                            
                download_from_studio_server(fromRS: url.absoluteString, toFS: savePanel.url!.absoluteString)
              }
              savePanel.close()
            }

            
          }
          
        }

        return(exportWV.webView)

        
      } else {
        
        let plotWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "plotPopupPanel") as! PlotWebViewController
        
        let plotWV = (plotWindowController.contentViewController as! plotPopupViewController)

        plotWV.view.window?.title = navigationAction.request.url!.absoluteString
        
        plotWV.setupWebView(configuration: configuration)
        plotWindowController.showWindow(self)
        plotWV.loadWebView(urlIn: navigationAction.request.url!.absoluteString)
        
        return(plotWV.webView)

      }
      
    }
    
    return(nil)
    
  }
  
//  func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
//    popupWebView = WKWebView(frame: view.bounds, configuration: configuration)
//    popupWebView!.autoresizingMask = [.width, .height]
//    popupWebView!.navigationDelegate = self
//    popupWebView!.uiDelegate = self
//    view.addSubview(popupWebView!)
//    return popupWebView!
//  }
//
  func webViewDidClose(_ webView: WKWebView) {
    if webView == popupWebView {
        popupWebView?.removeFromSuperview()
        popupWebView = nil
    }
  }
  
}

extension RstudioServerSessionWebViewController: WKNavigationDelegate {
  open func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
  }
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
  }
}
