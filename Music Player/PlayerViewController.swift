//
//  ViewController.swift
//  Music Player
//
//  Created by polat on 19/08/14.
//  Copyright (c) 2014 polat. All rights reserved.
// contact  bpolat@live.com

// Build 3 - July 1 2015 - Please refer git history for full changes
// Build 4 - Oct 24 2015 - Please refer git history for full changes

//Build 5 - Dec 14 - 2015 Adding shuffle - repeat


import UIKit
import AVFoundation
import MediaPlayer


class PlayerViewController: UIViewController, UITableViewDelegate,UITableViewDataSource,AVAudioPlayerDelegate {
    
    var audioPlayer:AVAudioPlayer! = nil
    var currentAudio = ""
    var currentAudioPath:NSURL!
    var audioList:NSArray!
    var currentAudioIndex = 0
    var timer:NSTimer!
    var audioLength = 0.0
    var toggle = true
    var effectToggle = true
    var totalLengthOfAudio = ""
    var finalImage:UIImage!
    var isTableViewOnscreen = false
    var shuffleState = false
    var repeatState = false
    var shuffleArray = [Int]()
    
    @IBOutlet var songNo : UILabel!
    @IBOutlet var lineView : UIView!
    @IBOutlet weak var albumArtworkImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet var songNameLabel : UILabel!
    @IBOutlet var songNameLabelPlaceHolder : UILabel!
    @IBOutlet var progressTimerLabel : UILabel!
    @IBOutlet var playerProgressSlider : UISlider!
    @IBOutlet var totalLengthOfAudioLabel : UILabel!
    @IBOutlet var previousButton : UIButton!
    @IBOutlet var playButton : UIButton!
    @IBOutlet var nextButton : UIButton!
    @IBOutlet var listButton : UIButton!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var blurImageView : UIImageView!
    @IBOutlet var enhancer : UIView!
    @IBOutlet var tableViewContainer : UIView!
    
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    
    
    
    @IBOutlet weak var tableViewContainerTopConstrain: NSLayoutConstraint!
    
    
    //MARK:- Lockscreen Media Control
    
    // This shows media info on lock screen - used currently and perform controls
    func showMediaInfo(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        let songName = readSongNameFromPlist(currentAudioIndex)
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : artistName,  MPMediaItemPropertyTitle : songName]
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event!.type == UIEventType.RemoteControl{
            switch event!.subtype{
            case UIEventSubtype.RemoteControlPlay:
                play(self)
            case UIEventSubtype.RemoteControlPause:
                play(self)
            case UIEventSubtype.RemoteControlNextTrack:
                next(self)
            case UIEventSubtype.RemoteControlPreviousTrack:
                previous(self)
            default:
                print("There is an issue with the control")
            }
        }
    }
    
        //MARK-
    
    
    // Table View Part of the code. Displays Song name and Artist Name
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell  {
        var songNameDict = NSDictionary();
        songNameDict = audioList.objectAtIndex(indexPath.row) as! NSDictionary
        let songName = songNameDict.valueForKey("songName") as! String
        
        var albumNameDict = NSDictionary();
        albumNameDict = audioList.objectAtIndex(indexPath.row) as! NSDictionary
        let albumName = albumNameDict.valueForKey("albumName") as! String
        
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.text = songName
        
        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.text = albumName
        return cell
    }
    
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54.0
    }
    
    
    
    func tableView(tableView: UITableView,willDisplayCell cell: UITableViewCell,forRowAtIndexPath indexPath: NSIndexPath){
        tableView.backgroundColor = UIColor.clearColor()
        
        let backgroundView = UIView(frame: CGRectZero)
        backgroundView.backgroundColor = UIColor.clearColor()
        cell.backgroundView = backgroundView
        cell.backgroundColor = UIColor.clearColor()
    }
    
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        animateTableViewToOffScreen()
        currentAudioIndex = indexPath.row
        prepareAudio()
        playAudio()
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        effectToggle ? "\(listButton.setImage( showList, forState: UIControlState.Normal))" : "\(listButton.setImage(removeList , forState: UIControlState.Normal))"
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        audioPlayer.playing ? "\(playButton.setImage( pause, forState: UIControlState.Normal))" : "\(playButton.setImage(play , forState: UIControlState.Normal))"
        
    }
    
    // Create blur effect by capturing screen and blurring it by core graphics.
    func captureScreen(){
        self.blurImageView.hidden = true
        self.blurImageView.alpha = 0.0
        
        UIGraphicsBeginImageContext(self.view.bounds.size);
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
    }
    
    //Apply blur effect to current screenshot
    func applyBlurEffect(image: UIImage){
        let context = CIContext(options: nil)
        let imageToBlur = CIImage(image: image)
        let blurfilter = CIFilter(name: "CIGaussianBlur")
        blurfilter!.setValue(imageToBlur, forKey: "inputImage")
        blurfilter!.setValue(5.0, forKey: "inputRadius")
        let resultImage = blurfilter!.valueForKey("outputImage") as! CIImage
        let cgImage = context.createCGImage(resultImage, fromRect: resultImage.extent)
        let blurredImage = UIImage(CGImage: cgImage)
        self.blurImageView.image = blurredImage
        self.blurImageView.hidden = false
        self.blurImageView.alpha = 1.0
        
    }
    
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default
    }
    
    override func prefersStatusBarHidden() -> Bool {
        
        if isTableViewOnscreen{
            return true
        }else{
            return false
        }
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //this sets last listened trach number as current
        retrieveSavedTrackNumber()
        prepareAudio()
        updateLabels()
        assingSliderUI()
        setRepeatAndShuffle()
        retrievePlayerProgressSliderValue()
        //LockScreen Media control registry
        if UIApplication.sharedApplication().respondsToSelector("beginReceivingRemoteControlEvents"){
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ () -> Void in
            })
        }

        
    }

    
    func setRepeatAndShuffle(){
        shuffleState = NSUserDefaults.standardUserDefaults().boolForKey("shuffleState")
        repeatState = NSUserDefaults.standardUserDefaults().boolForKey("repeatState")
        if shuffleState == true {
            shuffleButton.selected = true
        } else {
            shuffleButton.selected = false
        }
        
        if repeatState == true {
            repeatButton.selected = true
        }else{
            repeatButton.selected = false
        }
    
    }
    
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableViewContainerTopConstrain.constant = 800.0
        self.tableViewContainer.layoutIfNeeded()
        //Hide Artwork on iPhone 3,        
//        let iOSDeviceScreenSize = UIScreen.mainScreen().bounds.size
//        if iOSDeviceScreenSize.height != 480{
//            
//   
//        
//        }
        
        
        albumArtworkImageView.layer.cornerRadius = albumArtworkImageView.frame.size.width / 2
        albumArtworkImageView.clipsToBounds = true
        


        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK:- AVAudioPlayer Delegate's Callback method
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool){
        if flag == true {
            
            if shuffleState == false && repeatState == false {
                // do nothing
                playButton.setImage( UIImage(named: "play"), forState: UIControlState.Normal)
                return
            
            } else if shuffleState == false && repeatState == true {
            //repeat same song
                prepareAudio()
                playAudio()
            
            } else if shuffleState == true && repeatState == false {
            //shuffle songs but do not repeat at the end
            //Shuffle Logic : Create an array and put current song into the array then when next song come randomly choose song from available song and check against the array it is in the array try until you find one if the array and number of songs are same then stop playing as all songs are already played.
               shuffleArray.append(currentAudioIndex)
                if shuffleArray.count >= audioList.count {
                playButton.setImage( UIImage(named: "play"), forState: UIControlState.Normal)
                return
                
                }
                
                
                var randomIndex = 0
                var newIndex = false
                while newIndex == false {
                    randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
                    if shuffleArray.contains(randomIndex) {
                        newIndex = false
                    }else{
                        newIndex = true
                    }
                }
                currentAudioIndex = randomIndex
                prepareAudio()
                playAudio()
            
            } else if shuffleState == true && repeatState == true {
                //shuffle song endlessly
                shuffleArray.append(currentAudioIndex)
                if shuffleArray.count >= audioList.count {
                    shuffleArray.removeAll()
                }
                
                
                var randomIndex = 0
                var newIndex = false
                while newIndex == false {
                    randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
                    if shuffleArray.contains(randomIndex) {
                        newIndex = false
                    }else{
                        newIndex = true
                    }
                }
                currentAudioIndex = randomIndex
                prepareAudio()
                playAudio()
                
            
            }
            
        }
    }
    
    
    //Sets audio file URL
    func setCurrentAudioPath(){
        currentAudio = readSongNameFromPlist(currentAudioIndex)
        currentAudioPath = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource(currentAudio, ofType: "mp3")!)
        print("\(currentAudioPath)")
    }
    
    
    func saveCurrentTrackNumber(){
        NSUserDefaults.standardUserDefaults().setObject(currentAudioIndex, forKey:"currentAudioIndex")
        NSUserDefaults.standardUserDefaults().synchronize()
        
    }
    
    func retrieveSavedTrackNumber(){
        if let currentAudioIndex_ = NSUserDefaults.standardUserDefaults().objectForKey("currentAudioIndex") as? Int{
            currentAudioIndex = currentAudioIndex_
        }else{
            currentAudioIndex = 0
        }
    }


    
    // Prepare audio for playing
    func prepareAudio(){
        setCurrentAudioPath()
        do {
            //keep alive audio at background
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        audioPlayer = try? AVAudioPlayer(contentsOfURL: currentAudioPath)
        audioPlayer.delegate = self
        audioLength = audioPlayer.duration
        playerProgressSlider.maximumValue = CFloat(audioPlayer.duration)
        playerProgressSlider.minimumValue = 0.0
        playerProgressSlider.value = 0.0
        audioPlayer.prepareToPlay()
        showTotalSongLength()
        updateLabels()
        progressTimerLabel.text = "00:00"
        
        
    }
    
    //MARK:- Player Controls Methods
    func  playAudio(){
        audioPlayer.play()
        startTimer()
        updateLabels()
        saveCurrentTrackNumber()
        showMediaInfo()
    }
    
    func playNextAudio(){
        currentAudioIndex++
        if currentAudioIndex>audioList.count-1{
            currentAudioIndex--
            
            return
        }
        if audioPlayer.playing{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
        
    }
    
    
    func playPreviousAudio(){
        currentAudioIndex--
        if currentAudioIndex<0{
            currentAudioIndex++
            return
        }
        if audioPlayer.playing{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
        
    }
    
    
    func stopAudiplayer(){
        audioPlayer.stop();
        
    }
    
    func pauseAudioPlayer(){
        audioPlayer.pause()
        
    }
    
    
    //MARK:-
    
    func startTimer(){
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update:"), userInfo: nil,repeats: true)
            timer.fire()
        }
    }
    
    func stopTimer(){
        timer.invalidate()
        
    }
    
    
    func update(timer: NSTimer){
        if !audioPlayer.playing{
            return
        }
        let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
        progressTimerLabel.text  = "\(time.minute):\(time.second)"
        playerProgressSlider.value = CFloat(audioPlayer.currentTime)
        NSUserDefaults.standardUserDefaults().setFloat(playerProgressSlider.value , forKey: "playerProgressSliderValue")

        
    }
    
    func retrievePlayerProgressSliderValue(){
        let playerProgressSliderValue =  NSUserDefaults.standardUserDefaults().floatForKey("playerProgressSliderValue")
        if playerProgressSliderValue != 0 {
            playerProgressSlider.value  = playerProgressSliderValue
            audioPlayer.currentTime = NSTimeInterval(playerProgressSliderValue)
            
            let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
            progressTimerLabel.text  = "\(time.minute):\(time.second)"
            playerProgressSlider.value = CFloat(audioPlayer.currentTime)
            
        }else{
            playerProgressSlider.value = 0.0
            audioPlayer.currentTime = 0.0
            progressTimerLabel.text = "00:00:00"
        }
    }

    
    
    //This returns song length
    func calculateTimeFromNSTimeInterval(duration:NSTimeInterval) ->(minute:String, second:String){
       // let hour_   = abs(Int(duration)/3600)
        let minute_ = abs(Int((duration/60) % 60))
        let second_ = abs(Int(duration  % 60))
        
       // var hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        return (minute,second)
    }
    

    
    func showTotalSongLength(){
        calculateSongLength()
        totalLengthOfAudioLabel.text = totalLengthOfAudio
    }
    
    
    func calculateSongLength(){
        let time = calculateTimeFromNSTimeInterval(audioLength)
        totalLengthOfAudio = "\(time.minute):\(time.second)"
    }
    
    
    //Read plist file and creates an array of dictionary
    func readFromPlist(){
        let path = NSBundle.mainBundle().pathForResource("list", ofType: "plist")
        audioList = NSArray(contentsOfFile:path!)
    }
    
    func readArtistNameFromPlist(indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.objectAtIndex(indexNumber) as! NSDictionary
        let artistName = infoDict.valueForKey("artistName") as! String
        return artistName
    }
    
    func readAlbumNameFromPlist(indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.objectAtIndex(indexNumber) as! NSDictionary
        let albumName = infoDict.valueForKey("albumName") as! String
        return albumName
    }

    
    func readSongNameFromPlist(indexNumber: Int) -> String {
        readFromPlist()
        var songNameDict = NSDictionary();
        songNameDict = audioList.objectAtIndex(indexNumber) as! NSDictionary
        let songName = songNameDict.valueForKey("songName") as! String
        return songName
    }
    
    func readArtworkNameFromPlist(indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.objectAtIndex(indexNumber) as! NSDictionary
        let artworkName = infoDict.valueForKey("albumArtwork") as! String
        return artworkName
    }

    
    func updateLabels(){
        updateArtistNameLabel()
        updateAlbumNameLabel()
        updateSongNameLabel()
        updateAlbumArtwork()
    }
    
    
    func updateArtistNameLabel(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        artistNameLabel.text = artistName
    }
    func updateAlbumNameLabel(){
        let albumName = readAlbumNameFromPlist(currentAudioIndex)
        albumNameLabel.text = albumName
    }
    
    func updateSongNameLabel(){
        let songName = readSongNameFromPlist(currentAudioIndex)
        songNameLabel.text = songName
    }
    
    func updateAlbumArtwork(){
        let artworkName = readArtworkNameFromPlist(currentAudioIndex)
        albumArtworkImageView.image = UIImage(named: artworkName)
    }
    
  
    //creates animation and push table view to screen
    func animateTableViewToScreen(){
        self.tableViewContainerTopConstrain.constant = 0.0
        UIView.animateWithDuration(0.25, delay: 0.2, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.tableViewContainer.layoutIfNeeded()
            }, completion: nil)
    }
    
    
    
    
    func animateTableViewToOffScreen(){
        isTableViewOnscreen = false
        setNeedsStatusBarAppearanceUpdate()
        
        animateBlurImageBack()
        self.tableViewContainerTopConstrain.constant = 800.0

        UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
           self.tableViewContainer.layoutIfNeeded()
            
            }, completion: {
                (value: Bool) in
              //  self.enhancer.hidden = true
        })
    }
    
    
    func animateBlurImageBack(){
        UIView.animateWithDuration(0.25, delay: 0.2, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.blurImageView.alpha = 0.0
            }, completion: nil)
    }
    
   
    
    
    func addDropShadowToTableViewContainer(){
        self.tableViewContainer.layer.shadowColor = UIColor.blackColor().CGColor
        self.tableViewContainer.layer.shadowOffset = CGSizeMake(5.0,5.0)
        self.tableViewContainer.layer.masksToBounds = false
        self.tableViewContainer.layer.shadowRadius = 5.0
        self.tableViewContainer.layer.shadowOpacity = 1.0
    }
    
    func assingSliderUI () {
        let minImage = UIImage(named: "slider-track-fill")
        let maxImage = UIImage(named: "slider-track")
        let thumb = UIImage(named: "thumb")

        playerProgressSlider.setMinimumTrackImage(minImage, forState: .Normal)
        playerProgressSlider.setMaximumTrackImage(maxImage, forState: .Normal)
        playerProgressSlider.setThumbImage(thumb, forState: .Normal)

    
    }
    
    
    
    @IBAction func play(sender : AnyObject) {
        if shuffleState == true {
            shuffleArray.removeAll()
        }
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        if audioPlayer.playing{
            pauseAudioPlayer()
            audioPlayer.playing ? "\(playButton.setImage( pause, forState: UIControlState.Normal))" : "\(playButton.setImage(play , forState: UIControlState.Normal))"
            
        }else{
            playAudio()
            audioPlayer.playing ? "\(playButton.setImage( pause, forState: UIControlState.Normal))" : "\(playButton.setImage(play , forState: UIControlState.Normal))"
        }
    }
    
    
    
    @IBAction func next(sender : AnyObject) {
        playNextAudio()
    }
    
    
    @IBAction func previous(sender : AnyObject) {
        playPreviousAudio()
    }
    
    
    
    
    @IBAction func changeAudioLocationSlider(sender : UISlider) {
        audioPlayer.currentTime = NSTimeInterval(sender.value)
        
    }
    
    
    @IBAction func userTapped(sender : UITapGestureRecognizer) {
        
        play(self)
    }
    
    @IBAction func userSwipeLeft(sender : UISwipeGestureRecognizer) {
        next(self)
    }
    
    @IBAction func userSwipeRight(sender : UISwipeGestureRecognizer) {
        previous(self)
    }
    
    @IBAction func userSwipeUp(sender : UISwipeGestureRecognizer) {
        presentListTableView(self)
    }
    
    
    @IBAction func shuffleButtonTapped(sender: UIButton) {
        shuffleArray.removeAll()
        if sender.selected == true {
        sender.selected = false
        shuffleState = false
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "shuffleState")
        } else {
        sender.selected = true
        shuffleState = true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "shuffleState")
        }
        
        
        
    }
    
    
    @IBAction func repeatButtonTapped(sender: UIButton) {
        if sender.selected == true {
            sender.selected = false
            repeatState = false
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "repeatState")
        } else {
            sender.selected = true
            repeatState = true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "repeatState")
        }

        
    }
    
    
    
    
    @IBAction func presentListTableView(sender : AnyObject) {
        if effectToggle{
            isTableViewOnscreen = true
            setNeedsStatusBarAppearanceUpdate()
            captureScreen()
            self.applyBlurEffect(self.finalImage)
            //self.enhancer.hidden = false
//This line activates drop shadow effect on list of the song on table view. if you want shadow with list of the songs comment out following line
         //   addDropShadowToTableViewContainer()
            self.animateTableViewToScreen()
            
        }else{
            self.animateTableViewToOffScreen()
            
        }
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        effectToggle ? "\(listButton.setImage( showList, forState: UIControlState.Normal))" : "\(listButton.setImage(removeList , forState: UIControlState.Normal))"
    }
    
    
    
    
    
    
}