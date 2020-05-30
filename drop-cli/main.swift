//
//  main.swift
//  drop-cli
//
//  Created by Szymon Kaliski on 30/05/2020.
//  Copyright © 2020 Szymon Kaliski. All rights reserved.
//

import AppKit

// MARK: utlils -

func download(source: URL, to destination: URL, completion: @escaping (String?, Error?) -> Void) {
  if FileManager().fileExists(atPath: destination.path) {
    completion(destination.path, nil)
  } else if let dataFromURL = NSData(contentsOf: source) {
    if dataFromURL.write(to: destination, atomically: true) {
      completion(destination.path, nil)
    } else {
      let error = NSError(domain: "Error saving file", code: 1, userInfo: nil)
      completion(destination.path, error)
    }
  } else {
    let error = NSError(domain: "Error downloading file", code: 2, userInfo: nil)
    completion(destination.path, error)
  }
}

func temporaryFileURL(fileName: String = UUID().uuidString) -> URL {
  return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)
}

func synthesizeDrag(from window: NSWindow, at location: NSPoint) -> NSEvent? {
  return NSEvent.mouseEvent(with: .leftMouseDragged,
                            location: location,
                            modifierFlags: .deviceIndependentFlagsMask,
                            timestamp: 0,
                            windowNumber: window.windowNumber,
                            context: nil,
                            eventNumber: 0,
                            clickCount: 1,
                            pressure: 1)
}

// MARK: app -

class AppDelegate: NSObject, NSApplicationDelegate, NSDraggingSource {
  var urls: [URL] = []
  let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 1, height: 1), styleMask: [.borderless], backing: .buffered, defer: false, screen: nil)

  func applicationDidFinishLaunching(_: Notification) {
    window.makeKeyAndOrderFront(nil)

    let draggingItems = urls.map { (url) -> NSDraggingItem in
      let pasteboardItem = NSPasteboardItem()
      pasteboardItem.setData(url.dataRepresentation, forType: .fileURL)

      let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
      draggingItem.draggingFrame = CGRect(x: 0, y: 0, width: 1, height: 1)

      return draggingItem
    }

    if let dragEvent = synthesizeDrag(from: window, at: NSEvent.mouseLocation) {
      window.contentView?.beginDraggingSession(with: draggingItems, event: dragEvent, source: self)
      dragEvent.cgEvent?.post(tap: CGEventTapLocation.cghidEventTap)
    }
  }

  func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
    return .copy
  }

  func draggingSession(_: NSDraggingSession, endedAt _: NSPoint, operation _: NSDragOperation) {
    exit(0)
  }
}

// MARK: cli -

if CommandLine.arguments.count < 2 {
  print("pass files as arguments to this cli tool")
  exit(1)
}

let fileManager = FileManager.default
let currentPath = URL(fileURLWithPath: fileManager.currentDirectoryPath)
var urls: [URL] = []

for argument in CommandLine.arguments.dropFirst() {
  if argument.starts(with: "http") {
    if let urlArgument = URL(string: argument) {
      print("\(argument) looks like an URL, downloading...", terminator: "")

      let tempFile = temporaryFileURL().appendingPathExtension(urlArgument.pathExtension)

      download(source: urlArgument, to: tempFile, completion: { (path, error) in
        if error != nil {
          print("error")
          print(error.debugDescription)
        }
        else {
          urls.append(tempFile)
          print("done")
        }
      })
    }
  }
  else {
    let url = URL(fileURLWithPath: argument, relativeTo: currentPath)

    if fileManager.fileExists(atPath: url.path) {
      urls.append(url)
    }
    else {
      print("\(argument) doesn't seem to exist")
    }
  }
}

if urls.isEmpty {
  print("no existing files passed as arguments")
  exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
delegate.urls = urls

app.delegate = delegate
app.run()
