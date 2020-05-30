//
//  main.swift
//  rswitch-cmd
//
//  Created by boB Rudis on 4/25/20.
//  Copyright © 2020 Bob Rudis. All rights reserved.
//

import Foundation
import ArgumentParser

final class StandardErrorOutputStream: TextOutputStream {
  func write(_ string: String) {
    FileHandle.standardError.write(Data(string.utf8))
  }
}

func downloadAndUnpack(source : String, what : String) -> Bool {
    
  let tarballURL = URL(string: source)!

  let done = DispatchSemaphore(value: 0)
  var err = true

  let task = URLSession.shared.downloadTask(with: tarballURL) {
    fileURL, response, error in
    
    if (error != nil) {
      print("Error downloading \(what) \(String(describing: error))")
    } else if (response != nil) {
      
      let status = (response as? HTTPURLResponse)!.statusCode
      
      if (status < 300) {
        
        if (!(fileURL == nil) || (fileURL?.absoluteString != "")) {
                    
          print("Installing R-devel")
          
          do {
            let _ = try exec(program: "/usr/bin/tar", arguments: ["xzf", fileURL!.path, "-C", "/"])
            try FileManager.default.removeItem(at: fileURL!)
            err = false
          } catch {
            do {
              try FileManager.default.removeItem(at: fileURL!)
              err = false
            } catch {
              print("Error removing \(what) at: \(fileURL?.absoluteString ?? "")")
            }
          }

        } else {
          print("Error downloading \(what) \(String(describing: error))")
        }
        
      }
      
    }
    
    done.signal()
    
  }
  
  print("Starting download of \(what)")
  
  task.resume()
  done.wait()
  
  return(err)

}


struct RSwitch: ParsableCommand {
  
  static var configuration = CommandConfiguration(
    abstract: "Switch R versions.",
    version: "1.1.0"
  )
  
  @Flag(name: .shortAndLong, help: "List R versions.")
  var list: Bool
  
  @Flag(name: .long, help: "Install latest R-devel.")
  var installRDevel: Bool
  
  @Flag(name: .long,  help: "Install R-release daily build.")
  var installR: Bool
  
  @Flag(name: .long,  help: "Install latest RStudio Daily Build (Requires 'sudo'.")
  var installRStudio: Bool

  @Argument(help: "The R version to switch to.")
  var rversion: String?
    
  func run() throws {
    
    var outputStream = StandardErrorOutputStream()
    
    let targetPath = RVersions.currentVersionTarget()
    let versions = try RVersions.reloadVersions()
    
    if (installRDevel) {

      Darwin.exit(downloadAndUnpack(source: "https://mac.r-project.org/high-sierra/R-devel/x86_64/R-devel.tar.gz", what: "R-devel") ? 4 : 0)

    } else if (installR) {

      Darwin.exit(downloadAndUnpack(source: "https://mac.r-project.org/high-sierra/R-4.0-branch/x86_64/R-4.0-branch.tar.gz", what: "R-release") ? 5 : 0)
      
    } else if (installRStudio) {
      
      let sudo = !((ProcessInfo.processInfo.environment["SUDO_GID"] ?? "") == "")
      
      if (!sudo) {
        print("Installing RStudio requires elevated privileges. You must run this command with 'sudo'")
        Darwin.exit(6)
      }
      
    } else if (list || (rversion == nil)) {
      
      for version in versions {
        let complete = RVersions.hasRBinary(versionPath: version)
        var v = version
        if (version == targetPath) { v = v + " *" }
        if (!complete) { v = version + " (incomplete)" }
        print(v)
      }
      
    } else {
      
      if (!versions.contains(rversion!)) {
        
        print("R version " + rversion! + " not found.", to: &outputStream)
        Darwin.exit(3)
        
      } else {
        
        if (rversion! == targetPath) {
          print("Current R version already points to " + targetPath)
        } else {
          
          let fm = FileManager.default
          let rm_link = (RVersions.macos_r_framework as NSString).appendingPathComponent("Current")
          let new_link = (RVersions.macos_r_framework as NSString).appendingPathComponent(rversion!)
          
          do {
            try fm.removeItem(atPath: rm_link)
          } catch {
            print("Failed to remove existing R version symlink. Check file/directory permissions.", to: &outputStream)
            Darwin.exit(1)
          }
          
          do {
            try fm.createSymbolicLink(
              at: NSURL(fileURLWithPath: rm_link) as URL,
              withDestinationURL: NSURL(fileURLWithPath: new_link) as URL
            )
          } catch {
            print("Failed to create a symlink to the chosen R version. Check file/directory permissions.", to: &outputStream)
            Darwin.exit(2)
          }
          
          Darwin.exit(0)
          
        }
        
      }
      
    }
    
  }
  
}

RSwitch.main()
