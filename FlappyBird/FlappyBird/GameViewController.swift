//
//  GameViewController.swift
//  FlappyBird
//
//  Created by Luke on 20/08/14.
//  Copyright (c) 2014 Teegee. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            var sceneData: NSData?
            do {
                sceneData = try NSData(contentsOfFile:path, options: .DataReadingMappedIfSafe)
            } catch _ {
                sceneData = nil
            }
            let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData!)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, GameSceneDelegate {
    
    var backgroundMusicPlayer : AVAudioPlayer = AVAudioPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = self.view as! SKView
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        let scene = GameScene(size: skView.bounds.size, delegate:self, state:GameState.MainMenu)
        scene.scaleMode = .AspectFill

        skView.presentScene(scene)
        
        setupBackgroundMusic()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    func screenShot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 1.0)
        self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func share(string: String, url: NSURL, image: UIImage) {
        let activity:UIActivityViewController = UIActivityViewController(activityItems: [string, url, image], applicationActivities: nil)
        self.presentViewController(activity, animated: true, completion: nil)
    }

    func setupBackgroundMusic() {
        // Load the resource
        let musicURL = NSBundle.mainBundle().URLForResource("music", withExtension: "mp3")
        
        // Initialise the AVAudioPlayer with the resource's URL
        var error : NSError?        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOfURL: musicURL!)
        } catch let error1 as NSError {
            error = error1
        }
        
        // Set the file to loop and get it ready for play
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.volume = 1
        backgroundMusicPlayer.prepareToPlay()
        
        // Play the background music
        backgroundMusicPlayer.play()
    }
}
