//
//  AppDelegate.swift
//  HearBoard
//
//  Created by David Weinstein on 10/5/16.
//  Copyright © 2016 David Weinstein. All rights reserved.
//

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var statusMenu: NSMenu!
	@IBOutlet weak var preferencesMenu: NSMenu!

	@IBOutlet weak var songInfoView: SongInfoView!
	@IBOutlet weak var playControlView: PlayControlView!
	@IBOutlet weak var sizeSlider: NSSlider!
	@IBOutlet weak var scrollSpeedSlider: NSSlider!
	@IBOutlet weak var scrollTrackButton: NSButton!
	@IBOutlet weak var sizeView: SizeView!
	@IBOutlet weak var scrollSpeedView: ScrollSpeedView!
	@IBOutlet weak var scrollTrackView: ScrollTrackView!

	@IBOutlet weak var songInfoTrack: NSTextField!
	@IBOutlet weak var songInfoArtist: NSTextField!
	@IBOutlet weak var playPauseItem: NSButton!
	@IBOutlet weak var albumArt: NSImageView!

	var sizeMenuItem: NSMenuItem!
	var scrollSpeedMenuItem: NSMenuItem!
	var scrollTrackMenuItem: NSMenuItem!
	var songInfoMenuItem: NSMenuItem!
	var playControlsMenuItem: NSMenuItem!
	
	@IBOutlet weak var settingsMenuItem: NSMenuItem!
	let defaults = UserDefaults.standard
	
	var path = "./Applications/HearBoard.app/Contents/Resources/config.data"
	
	
	var DISPLAYED_CHARS = 20
	var SCROLL_DELAY = 0.25
	
	let FRAME_RATE = 0.25
	var ALLOW_SCROLLING = true
	var length: CGFloat?

	var statusItem: NSStatusItem?
	var prevTrack = ""
	var scrollCount = 0
	var frameCount = 0
	var neededFramesForScroll: Int?
	var nowPlaying = NowPlaying()
	var needsRefresh = false
	
	
	var timer: Timer?
	
	@IBAction func sizeMoved(_ sender: NSSlider) {
		let newDisplayedChars = sender.floatValue * 0.4
		DISPLAYED_CHARS = max(Int(newDisplayedChars), 1)
		length = CGFloat(DISPLAYED_CHARS) * 7.5
		NSStatusBar.system().removeStatusItem(self.statusItem!)
		self.statusItem = NSStatusBar.system().statusItem(withLength: length!)
		needsRefresh = true
	}
	@IBAction func scrollSpeedMoved(_ sender: NSSlider) {
		let newScrollDelay = (100 - sender.floatValue) * 0.005
		SCROLL_DELAY = Double(newScrollDelay)
		needsRefresh = true
	}

	@IBAction func scrollTrackClicked(_ sender: NSButton) {
		ALLOW_SCROLLING = !ALLOW_SCROLLING
		needsRefresh = true
	}
	@IBAction func quitClicked(_ sender: NSMenuItem) {
		let file: FileHandle? = FileHandle(forWritingAtPath: path)
		if file != nil {
			let data = (String(DISPLAYED_CHARS) + "\n" + String(SCROLL_DELAY) + "\n" + String(ALLOW_SCROLLING) + "\n" as NSString).data(using: String.Encoding.utf8.rawValue)
			file?.write(data!)
			file?.closeFile()
		} else {
			print("Error in saving config")
		}
		NSApplication.shared().terminate(self)
	}
	@IBAction func playPauseClicked(_ sender: NSButton) {
		nowPlaying.playPause()
		if(nowPlaying.isPlaying()) {
			playPauseItem.image = #imageLiteral(resourceName: "Pause")
		}
		else {
			playPauseItem.image = #imageLiteral(resourceName: "Play")
		}
	}
	
	@IBAction func prevTrackClicked(_ sender: NSButton) {
		nowPlaying.playPrev()
		songInfoTrack.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentTrack())
		songInfoArtist.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentArtist())
		albumArt.image = nowPlaying.getAlbumArt()
		if(nowPlaying.isPlaying()) {
			playPauseItem.image = #imageLiteral(resourceName: "Pause")
		}
		else {
			playPauseItem.image = #imageLiteral(resourceName: "Play")
		}
	}
	
	@IBAction func nextTrackClicked(_ sender: NSButton) {
		nowPlaying.playNext()
		songInfoTrack.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentTrack())
		songInfoArtist.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentArtist())
		albumArt.image = nowPlaying.getAlbumArt()
		if(nowPlaying.isPlaying()) {
			playPauseItem.image = #imageLiteral(resourceName: "Pause")
		}
		else {
			playPauseItem.image = #imageLiteral(resourceName: "Play")
		}
	}
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		do {
			let fileContents = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
			let settings:Array<String> = NSString(string: fileContents).components(separatedBy: "\n")
			DISPLAYED_CHARS = Int(settings[0])!
			let sizeKnob = Double(DISPLAYED_CHARS) / 0.4
			sizeSlider.floatValue = Float(sizeKnob)
			SCROLL_DELAY = Double(settings[1])!
			var scrollKnob = Double(SCROLL_DELAY) / 0.005
			scrollKnob -= 100
			scrollKnob *= -1
			scrollSpeedSlider.floatValue = Float(scrollKnob)
			ALLOW_SCROLLING = Bool(settings[2])!
			if(!ALLOW_SCROLLING) {
				scrollTrackButton.setNextState()
			}
		} catch {
			print("File not found: " + path)
		}
		songInfoMenuItem = statusMenu.item(withTitle: "Song Info")
		songInfoMenuItem.view = songInfoView
		playControlsMenuItem = statusMenu.item(withTitle: "Play Controls")
		playControlsMenuItem.view = playControlView
		sizeMenuItem = preferencesMenu.item(withTitle: "Size")
		sizeMenuItem.view = sizeView
		scrollSpeedMenuItem = preferencesMenu.item(withTitle: "ScrollSpeed")
		scrollSpeedMenuItem.view = scrollSpeedView
		scrollTrackMenuItem = preferencesMenu.item(withTitle: "ScrollTrack")
		scrollTrackMenuItem.view = scrollTrackView
		
		
		if(nowPlaying.isPlaying()) {
			playPauseItem.image = #imageLiteral(resourceName: "Pause")
		}
		else {
			playPauseItem.image = #imageLiteral(resourceName: "Play")
		}
		
		albumArt.image = nowPlaying.getAlbumArt()
		
		neededFramesForScroll = Int(ceil(5 /	SCROLL_DELAY))
		length = CGFloat(DISPLAYED_CHARS) * 7.5
		self.statusItem = NSStatusBar.system().statusItem(withLength: length!)
		
		DispatchQueue.global().async {
			DispatchQueue.main.async(execute: {
				self.displayTrackInThread(interval: self.SCROLL_DELAY)
			})
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		
	}
	
	func displayTrackInThread(interval: Double) {
		needsRefresh = false
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: FRAME_RATE, target: self, selector: #selector(AppDelegate.displayTrack), userInfo: nil, repeats: true)
	}
	
	func displayTrackInThreadAndScroll(interval: Double) {
		timer?.invalidate()
		timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(AppDelegate.displayTrackAndScroll), userInfo: nil, repeats: true)
	}
	
	func displayTrack() {
		
		if(nowPlaying.isPlaying()) {
			playPauseItem.image = #imageLiteral(resourceName: "Pause")
		}
		else {
			playPauseItem.image = #imageLiteral(resourceName: "Play")
		}
		
		var trackAndArtist = nowPlaying.nowPlaying()
		if trackAndArtist == "error - error" {
			trackAndArtist = ""
			self.statusItem = NSStatusBar.system().statusItem(withLength: 0)
		}
		else {
			length = CGFloat(DISPLAYED_CHARS) * 7.5
//			self.statusItem = NSStatusBar.system().statusItem(withLength: length!)
		}
		
		if(trackAndArtist != prevTrack) {
			albumArt.image = nowPlaying.getAlbumArt()
		}
		prevTrack = trackAndArtist
		
		if trackAndArtist != "" {
			for _ in 0...DISPLAYED_CHARS {
				trackAndArtist += "\t"
			}
		}
		
		statusItem?.title = trackAndArtist
		statusItem?.menu = statusMenu
		
		songInfoTrack.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentTrack())
		songInfoArtist.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentArtist())
		
		frameCount += 1
		if(frameCount == neededFramesForScroll) {
			frameCount = 0
			if(ALLOW_SCROLLING && nowPlaying.isPlaying()) {
				displayTrackInThreadAndScroll(interval: SCROLL_DELAY)
			}
		}
		
	}
	
	func displayTrackAndScroll() {
		
		if(nowPlaying.isPlaying()) {
			playPauseItem.image = #imageLiteral(resourceName: "Pause")
		}
		else {
			playPauseItem.image = #imageLiteral(resourceName: "Play")
			scrollCount = 0
			displayTrackInThread(interval: FRAME_RATE)
		}
		
		var trackAndArtist = nowPlaying.nowPlaying()
		if trackAndArtist == "error - error" {
			trackAndArtist = ""
		}
		
		if prevTrack != trackAndArtist {
			scrollCount = 0
			songInfoTrack.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentTrack())
			songInfoArtist.stringValue = shortenIfTooLong(text: nowPlaying.getCurrentArtist())
			displayTrackInThread(interval: SCROLL_DELAY)
			albumArt.image = nowPlaying.getAlbumArt()
		}
		prevTrack = trackAndArtist
		
		if trackAndArtist != "" {
			for _ in 0...DISPLAYED_CHARS {
				trackAndArtist += "\t"
			}
		}
		
		let charCount = trackAndArtist.characters.count
		let totalLength = scrollCount + DISPLAYED_CHARS

		let start = trackAndArtist.index(trackAndArtist.startIndex, offsetBy: scrollCount)

		let range = start..<trackAndArtist.endIndex
		let substring = trackAndArtist.substring(with: range)
		
		statusItem?.title = substring
		statusItem?.menu = statusMenu

		scrollCount += 1
		if totalLength >= charCount || needsRefresh{
			scrollCount = 0
			displayTrackInThread(interval: FRAME_RATE)
		}
	}
	
	func shortenIfTooLong(text: String) -> String {
		var returnString = ""
		if(text.characters.count > DISPLAYED_CHARS - 3) {
			var subStringLength = max(DISPLAYED_CHARS - 6, 15)
			let characters = Array(text.characters)
			subStringLength = min(characters.count - 1, subStringLength);
			for index in 0...subStringLength {
				returnString += String(characters[index])
			}
			returnString += "..."
			return returnString
		}
		return text
	}
}

