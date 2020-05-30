//
//  main.swift
//  drop-cli
//
//  Created by Szymon Kaliski on 30/05/2020.
//  Copyright © 2020 Szymon Kaliski. All rights reserved.
//

import AppKit

// MARK: app -

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

class AppDelegate: NSObject, NSApplicationDelegate, NSDraggingSource {
  var fileUrls: [URL] = []
  let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 1, height: 1), styleMask: [.borderless], backing: .buffered, defer: false, screen: nil)

  func applicationDidFinishLaunching(_ notification: Notification) {
    window.makeKeyAndOrderFront(nil)

    let draggingItems = fileUrls.map { (url) -> NSDraggingItem in
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

  func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
    return .copy
  }

  func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
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
var fileUrls: [URL] = []

for argument in CommandLine.arguments.dropFirst() {
  let url = URL(fileURLWithPath: argument, relativeTo: currentPath)

  if fileManager.fileExists(atPath: url.path) {
    fileUrls.append(url)
  }
}

if fileUrls.isEmpty {
  print("no existing files passed as arguments")
  exit(1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
delegate.fileUrls = fileUrls

app.delegate = delegate
app.run()
