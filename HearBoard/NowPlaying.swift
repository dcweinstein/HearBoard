//
//  NowPlaying.swift
//  HearBoard
//
//  Created by David Weinstein on 10/6/16.
//  Copyright © 2016 David Weinstein. All rights reserved.
//

import Foundation
import Cocoa

class NowPlaying {
	var currentTrack = ""
	var currentArtist = ""
	
	init() {
		currentTrack = self.getCurrentTrack()
		currentArtist = self.getCurrentArtist()
	}
	
	func nowPlaying() -> String {
		currentTrack = self.getCurrentTrack()
		currentArtist = self.getCurrentArtist()
		return currentArtist + " - " + currentTrack
	}
	
	func getCurrentTrack() -> String {
		
		let trackScript = "if application \"Spotify\" is running then\ntell application \"Spotify\"\n set currentTrack to name of current track as string\n return currentTrack\n end tell\n else\nreturn \"error\"\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: trackScript) {
			if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				return output.stringValue!
			} else if (error != nil) {
				print("error1: \(error)")
			}
		}
		
		return "error"
	}
	
	func getCurrentArtist() -> String {
		let artistScript = "if application \"Spotify\" is running then\ntell application \"Spotify\"\n set currentArtist to artist of current track as string\n return currentArtist\n end tell\n else\nreturn \"error\"\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: artistScript) {
			if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				return output.stringValue!
			} else if (error != nil) {
				print("error2: \(error)")
			}
		}
		
		return "error"
	}
	
	func playPause() {
		let playPauseScript = "if application\"Spotify\" is running then\ntell application \"Spotify\"\nplaypause\nend tell\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: playPauseScript) {
			if let _: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				if (error != nil) {
					print("Error on Play/Pause: \(error)")
				}
			}
		}
	}
	
	func playNext() {
		let playNextScript = "if application\"Spotify\" is running then\ntell application \"Spotify\"\nnext track\nend tell\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: playNextScript) {
			if let _: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				if (error != nil) {
					print("Error on next track: \(error)")
				}
			}
		}
	}
	
	func playPrev() {
		let playPrevScript = "if application\"Spotify\" is running then\ntell application \"Spotify\"\nprevious track\nend tell\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: playPrevScript) {
			if let _: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				if (error != nil) {
					print("Error on Prev track: \(error)")
				}
			}
		}
	}
	
	func getAlbumArt() -> NSImage{
		
		let albumArtScript = "if application\"Spotify\" is running then\ntell application \"Spotify\"\nset artworkURL to artwork url of current track\nreturn artworkURL\nend tell\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: albumArtScript) {
			if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				if(output.stringValue != nil) {
					let url = URL(string: output.stringValue!)
					print("URL: " + output.stringValue!)
					return NSImage(contentsOf: (url)!)!
				}
			} else if (error != nil) {
				print("Error getting Album Art: \(error)")
			}

		}
		return NSImage()
	}
	
	func isPlaying() -> Bool {
		let isPlayingScript = "if application \"Spotify\" is running then\ntell application \"Spotify\"\nset state to player state\nreturn state\nend tell\nelse\nreturn \"error\"\nend if"
		
		var error: NSDictionary?
		
		if let scriptObject = NSAppleScript(source: isPlayingScript) {
			if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
				let state = output.stringValue!
				if(state == "kPSP") {
					return true
				}
			}
		}
		return false
	}
}
