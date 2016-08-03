//
//  ViewController.swift
//  MediaPlayground
//
//  Created by Koby Samuel on 11/30/15.
//  Copyright © 2015 Koby Samuel. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation
import MediaPlayer

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MPMediaPickerControllerDelegate {
	@IBOutlet weak var toggleFullscreen: UISwitch!
	@IBOutlet weak var movieRegion: UIView!
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var toggleCamera: UISwitch!
	@IBOutlet weak var displayImageView: UIImageView!
	@IBOutlet weak var musicPlayButton: UIButton!
	@IBOutlet weak var displayNowPlaying: UILabel!
	var moviePlayer: MPMoviePlayerController!
	var audioRecorder: AVAudioRecorder!
	var audioPlayer: AVAudioPlayer!
	var musicPlayer: MPMusicPlayerController!
	
	@IBAction func playMovie(sender: AnyObject) {
		view.addSubview(moviePlayer.view)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "playMovieFinished:", name: MPMoviePlayerPlaybackDidFinishNotification, object: moviePlayer)
		if(toggleFullscreen.on) {
			moviePlayer.setFullscreen(true, animated: true)
		}
		moviePlayer.play()
	}
	
	@IBAction func recordAudio(sender: AnyObject) {
		if recordButton.titleLabel!.text == "Record Audio" {
			audioRecorder.record()
			recordButton.setTitle("Stop Recording", forState:  UIControlState.Normal)
		}
		else {
			audioRecorder.stop()
			recordButton.setTitle("Record Audio", forState: UIControlState.Normal)
		}
		let soundFileURL: NSURL = NSURL.fileURLWithPath(NSTemporaryDirectory() + "sound.caf")
		do {
			try audioPlayer = AVAudioPlayer(contentsOfURL: soundFileURL)
		}
		catch{}
	}
	
	@IBAction func playAudio(sender: AnyObject) {
		audioPlayer.play()
	}
	
	@IBAction func chooseImage(sender: AnyObject) {
		let imagePicker: UIImagePickerController = UIImagePickerController()
		if toggleCamera.on {
			imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
		}
		else {
			imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
		}
		imagePicker.delegate = self
		imagePicker.allowsEditing = true
		imagePicker.modalPresentationStyle = UIModalPresentationStyle.Popover
		if(imagePicker.popoverPresentationController != nil) {
			imagePicker.popoverPresentationController!.sourceView = sender as! UIButton
			imagePicker.popoverPresentationController!.sourceRect = (sender as! UIButton).bounds
		}
		presentViewController(imagePicker, animated: true, completion: nil)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
		dismissViewControllerAnimated(true, completion: nil)
		displayImageView.image = info[UIImagePickerControllerEditedImage] as! UIImage!
	}
	
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func applyFilter(sender: AnyObject) {
		let imageToFilter: CIImage = CIImage(image: self.displayImageView.image!)!
		let activeFilter: CIFilter = CIFilter(name: "CISepiaTone")!
		activeFilter.setDefaults()
		activeFilter.setValue(0.75, forKey: "inputIntensity")
		activeFilter.setValue(imageToFilter, forKey: "inputImage")
		let filteredImage: CIImage = activeFilter.valueForKey("outputImage") as! CIImage
		let myNewImage: UIImage = UIImage(CIImage: filteredImage)
		displayImageView.image = myNewImage
	}
	
	@IBAction func chooseMusic(sender: AnyObject) {
		musicPlayer.stop()
		displayNowPlaying.text = "No Song Playing"
		musicPlayButton.setTitle("Play Music", forState: UIControlState.Normal)
		let musicPicker: MPMediaPickerController = MPMediaPickerController(mediaTypes: MPMediaType.Music)
		musicPicker.prompt = "Choose Songs to Play"
		musicPicker.allowsPickingMultipleItems = true
		musicPicker.delegate = self
		musicPicker.modalPresentationStyle = UIModalPresentationStyle.Popover
		if(musicPicker.popoverPresentationController != nil) {
			musicPicker.popoverPresentationController!.sourceView = sender as! UIButton
			musicPicker.popoverPresentationController!.sourceRect = (sender as! UIButton).bounds
		}
		presentViewController(musicPicker, animated: true, completion: nil)
	}
	
	func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		musicPlayer.setQueueWithItemCollection(mediaItemCollection)
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func playMusic(sender: AnyObject) {
		if(musicPlayButton.titleLabel!.text == "Play Music") {
			musicPlayer.play()
			musicPlayButton.setTitle("Pause Music", forState: UIControlState.Normal)
			let currentSong: MPMediaItem = musicPlayer.nowPlayingItem!
			displayNowPlaying.text = currentSong.valueForProperty(MPMediaItemPropertyTitle) as! String!
		}
		else {
			musicPlayer.pause()
			musicPlayButton.setTitle("Play Music", forState: UIControlState.Normal)
			displayNowPlaying.text = "No Song Playing"
		}
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		let movieFile: String = NSBundle.mainBundle().pathForResource("movie", ofType: "m4v")!
		moviePlayer = MPMoviePlayerController(contentURL: NSURL(fileURLWithPath: movieFile))
		moviePlayer.allowsAirPlay = true
		moviePlayer.view.frame = self.movieRegion.frame
	}
	
	func playMovieFinished(notification: NSNotification) {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: MPMoviePlayerPlaybackDidFinishNotification, object: moviePlayer)
		moviePlayer.view.removeFromSuperview()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		do {
			try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
		}
		catch {}
		let soundFileURL: NSURL = NSURL.fileURLWithPath(NSTemporaryDirectory() + "sound.caf")
		let soundSetting: [String: AnyObject] =
		[
			AVSampleRateKey: 44100.0 as NSNumber,
			AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
			AVNumberOfChannelsKey: 2 as NSNumber,
			AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue as NSNumber
		]
		do {
			try audioRecorder = AVAudioRecorder(URL: soundFileURL, settings:  soundSetting)
		}
		catch {}
		let noSoundFileURL: NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("norecording", ofType: "wav")!)
		do {
			try audioPlayer = AVAudioPlayer(contentsOfURL: noSoundFileURL)
		}
		catch {}
		musicPlayer = MPMusicPlayerController.systemMusicPlayer()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

