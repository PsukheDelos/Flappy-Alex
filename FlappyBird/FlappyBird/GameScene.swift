//
//  GameScene.swift
//  FlappyBird
//
//  Created by Luke on 20/08/14.
//  Copyright (c) 2014 Teegee. All rights reserved.
//

import SpriteKit
import AVFoundation

protocol GameSceneDelegate {
    func screenShot() -> UIImage
    func share(string:String, url:NSURL, image:UIImage) -> Void
}

enum Layer:Int {
    case LayerBackground = 1, LayerMidground, LayerObstacle, LayerForeground, LayerPlayer, LayerFlash, LayerUI
    
    func floatValue() -> CGFloat {
        return CGFloat(self.rawValue)
    }
}

enum GameState:Int {
    case MainMenu = 1, Tutorial, Play, Falling, ShowingScore, GameOver
}

struct EntityCategory : OptionSetType, BooleanType {    
    typealias RawValue = UInt32
    private var value: UInt32 = 0
    init(_ value: UInt32) { self.value = value }
    var boolValue: Bool { return self.value != 0 }
    init(rawValue value: UInt32) { self.value = value }
    init(nilLiteral: ()) { self.value = 0 }
    static var allZeros: EntityCategory { return self.init(0) }
    static func fromMask(raw: UInt32) -> EntityCategory { return self.init(raw) }
    var rawValue: UInt32 { return self.value }
    
    static var None: EntityCategory         { return self.init(0) }
    static var Player: EntityCategory       { return self.init(1 << 0) }
    static var Obstacle: EntityCategory     { return self.init(1 << 1) }
    static var Ground: EntityCategory       { return self.init(1 << 2) }
} 

// Helper function
func randomFloatRange(min:CGFloat, max:CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (max - min) + min;
}

func degreesToRadians(degrees:CGFloat) -> CGFloat {
    return CGFloat(M_PI) * degrees / 180.0;
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Gameplay - Bird movement
    let kGravity:CGFloat = -1300.0
    let kImpulse:CGFloat = 400
    
    // Gameplay - Foreground moving
    let kNumForegrounds:Int = 2
    let kForegroundSpeed:CGFloat = 150;
    
    // Gameplay - Midground moving
    let kNumMidgrounds:Int = 2
    let kMidgroundSpeedModifier:CGFloat = 0.5
    
    // Gameplay - Obstacle positioning
    let kGapMultiplier:CGFloat = 3.5
    let kBottomObstacleMinFraction:CGFloat = 0.1
    let kBottomObstacleMaxFraction:CGFloat = 0.6
    
    // Gameplay - Obstacle spawn timing
    let kFirstSpawnDelay:Double = 1.5
    let kSpawnDelay:Double = 1.5
    
    // Gameplay - Ghost
    let kGhostSpeed:CGFloat = 200
    
    // UI - Score label
    let kLabelYOffset:CGFloat = 20
    let kFontName:String = "Omnes-Semibold"
    let kFontColor:SKColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let kAnimationDelay:Double = 0.3
    
    let APP_STORE_ID:Int = 90183021
    
    var gameSceneDelegate:GameSceneDelegate
    var worldNode:SKNode = SKNode()
    var player:SKSpriteNode?
    var ghost:SKSpriteNode?
    var scoreLabel:SKLabelNode?
    
    var playableStart : CGFloat = 0.0
    var playableHeight : CGFloat = 0.0
    var playerVelocity : CGPoint = CGPoint(x: 0, y: 0)
    var lastUpdatedTime : NSTimeInterval = 0
    
    // Sounds
    var coinAction : SKAction?
    var dingAction : SKAction?
    var popAction : SKAction?
    var jumpSound : AVAudioPlayer?
    var deathSound : AVAudioPlayer?
    
    var gameState : GameState
    var hitGround : Bool
    var hitObstacle : Bool
    
    // Score
    var score:Int = 0
    
    init(size: CGSize, delegate:GameSceneDelegate, state:GameState) {
        gameState = state
        hitGround = false
        hitObstacle = false
        self.gameSceneDelegate = delegate
        
        super.init(size:size)
        
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.addChild(worldNode)
        
        if (state == GameState.MainMenu) {
            self.switchToMainMenu()
        }
        else {
            self.switchToTutorial()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "Background")
        background.anchorPoint = CGPoint(x:0.5, y:1.0)
        background.position = CGPoint(x:self.size.width / 2.0, y:self.size.height);
        background.zPosition = Layer.LayerBackground.floatValue()
        worldNode.addChild(background)
        
        playableStart = self.size.height - background.size.height
        playableHeight = background.size.height
        
        let lowerLeft:CGPoint = CGPoint(x: 0, y: playableStart)
        let lowerRight:CGPoint = CGPoint(x: self.size.width, y: playableStart)
        
        self.physicsBody = SKPhysicsBody(edgeFromPoint: lowerLeft, toPoint: lowerRight)
        //self.attachDebugLineFromPoint(lowerLeft, to: lowerRight, color: UIColor.redColor())
        
        self.physicsBody!.categoryBitMask = EntityCategory.Ground.rawValue
        self.physicsBody!.collisionBitMask = 0
        self.physicsBody!.contactTestBitMask = EntityCategory.Player.rawValue
    }
    
    func setupMidground() {
        for (var i:Int = 0; i < kNumMidgrounds; ++i) {
            let midground = SKSpriteNode(imageNamed: "Midground")
            midground.anchorPoint = CGPoint(x: 0, y: 1)
            midground.position = CGPoint(x: (CGFloat(i) * midground.size.width), y: self.size.height)
            midground.zPosition = Layer.LayerMidground.floatValue()
            midground.name = "Midground"
            worldNode.addChild(midground)
        }
    }
    
    func setupForeground() {
        for (var i:Int = 0; i < kNumForegrounds; ++i) {
            let foreground = SKSpriteNode(imageNamed: "Ground")
            foreground.anchorPoint = CGPoint(x: 0, y: 1)
            foreground.position = CGPoint(x: (CGFloat(i) * foreground.size.width), y: playableStart)
            foreground.zPosition = Layer.LayerForeground.floatValue()
            foreground.name = "Foreground"
            worldNode.addChild(foreground)
        }
    }
    
    func setupPlayer() {
        player = SKSpriteNode(imageNamed: "Bird0")
        player!.position = CGPoint(x: self.size.width * 0.2, y: playableHeight * 0.4 + playableStart)
        player!.zPosition = Layer.LayerPlayer.floatValue()
        worldNode.addChild(player!)
        
        let offsetX:CGFloat = player!.size.width * player!.anchorPoint.x
        let offsetY:CGFloat = player!.size.height * player!.anchorPoint.y
        
        let path:CGMutablePathRef = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 3-offsetX, 10-offsetY)
        CGPathAddLineToPoint(path, nil, 17-offsetX, 23-offsetY)
        CGPathAddLineToPoint(path, nil, 34-offsetX, 28-offsetY)
        CGPathAddLineToPoint(path, nil, 39-offsetX, 16-offsetY)
        CGPathAddLineToPoint(path, nil, 33-offsetX, 4-offsetY)
        CGPathAddLineToPoint(path, nil, 18-offsetX, 1-offsetY)
        CGPathAddLineToPoint(path, nil, 6-offsetX, 1-offsetY)
        CGPathCloseSubpath(path)
        
        player!.physicsBody = SKPhysicsBody(polygonFromPath: path)
        //player!.attachDebugFrameFromPath(path, color: SKColor.redColor())
        player!.physicsBody!.categoryBitMask = EntityCategory.Player.rawValue
        
        var playerContact:EntityCategory = [EntityCategory.Obstacle, EntityCategory.Ground]
        player!.physicsBody!.collisionBitMask = 0
        player!.physicsBody!.contactTestBitMask = playerContact.rawValue
        player!.physicsBody!.dynamic = true
        
    }
    
    func setupGhost() {
        ghost = SKSpriteNode(imageNamed: "Death0")
        ghost!.position = player!.position
        ghost!.zPosition = Layer.LayerPlayer.floatValue()
        worldNode.addChild(ghost!)
        
        // Death animation
        var deathTextures = Array<SKTexture>()
        for (var i:Int = 0; i < 2; ++i) {
            deathTextures.append(SKTexture(imageNamed: String("Death"+String(i))))
        }
        
        for (var i:Int = 1; i >= 0; --i) {
            deathTextures.append(SKTexture(imageNamed: String("Death"+String(i))))
        }
        
        let deathAnimation:SKAction = SKAction.animateWithTextures(deathTextures as [SKTexture], timePerFrame: 0.075)
        ghost!.runAction(SKAction.repeatActionForever(deathAnimation))
        
        
        if (player!.parent != nil) {
            player!.removeFromParent()
        }
    }
    
    func setupSounds() {
        coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
        dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
        popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
        
        jumpSound = loadSound("jump", format: "mp3", volume: 0.1)
        deathSound = loadSound("death", format: "mp3", volume: 0.1)
    }
    
    func loadSound(soundFile:String, format:String, volume:Float) -> AVAudioPlayer? {
        // Load the resource
        let musicURL = NSBundle.mainBundle().URLForResource(soundFile, withExtension: format)
        
        // Initialise the AVAudioPlayer with the resource's URL
        var error : NSError? = nil        
        var soundPlayer:AVAudioPlayer?
        do {
            soundPlayer = try AVAudioPlayer(contentsOfURL: musicURL!)
        } catch let error1 as NSError {
            error = error1
        }
        
        // Set the file to loop and get it ready for play
        if let thisPlayer = soundPlayer {
            thisPlayer.numberOfLoops = 0
            thisPlayer.volume = volume
            thisPlayer.prepareToPlay()
        }
        
        return soundPlayer
    }
    
    func setupScore() {
        scoreLabel = SKLabelNode(fontNamed: kFontName)
        scoreLabel!.fontColor = kFontColor
        scoreLabel!.verticalAlignmentMode = .Top
        scoreLabel!.horizontalAlignmentMode = .Center
        scoreLabel!.position = CGPoint(x: self.size.width / 2.0, y: self.size.height - kLabelYOffset)
        scoreLabel!.text = "0"
        scoreLabel!.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(scoreLabel!)
    }
    
    func setupTutorial() {
        let tutorial:SKSpriteNode = SKSpriteNode(imageNamed: "Tutorial")
        tutorial.position = CGPoint(x: Int(self.size.width / 2.0), y: Int(playableHeight * 0.4 + playableStart))
        tutorial.name = "Tutorial"
        tutorial.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(tutorial)
        
        let ready:SKSpriteNode = SKSpriteNode(imageNamed: "Ready")
        ready.position = CGPoint(x: self.size.width / 2.0, y: playableHeight * 0.7 + playableStart)
        ready.name = "Tutorial"
        ready.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(ready)
    }
    
    func setupScoreCard() {
        setBestScore(score)
        
        let scoreCard:SKSpriteNode = SKSpriteNode(imageNamed: "ScoreCard")
        scoreCard.position = CGPoint(x: self.size.width / 2.0, y: self.size.height / 2.0)
        scoreCard.name = "Tutorial"
        scoreCard.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(scoreCard)
        
        let lastScore:SKLabelNode = SKLabelNode(fontNamed: kFontName)
        lastScore.fontColor = kFontColor
        lastScore.position = CGPoint(x: -scoreCard.size.width * 0.25, y: -scoreCard.size.height * 0.2)
        lastScore.text = String(score)
        scoreCard.addChild(lastScore)
        
        let bestScore:SKLabelNode = SKLabelNode(fontNamed: kFontName)
        bestScore.fontColor = kFontColor
        bestScore.position = CGPoint(x: scoreCard.size.width * 0.25, y: -scoreCard.size.height * 0.2)
        bestScore.text = String(self.bestScore())
        scoreCard.addChild(bestScore)
        
        let gameOver:SKSpriteNode = SKSpriteNode(imageNamed: "GameOver")
        gameOver.position = CGPoint(x: self.size.width / 2.0, y: self.size.height / 2.0 + scoreCard.size.height / 2.0 + kLabelYOffset + gameOver.size.height / 2.0)
        gameOver.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(gameOver)
        
        let okButton:SKSpriteNode = SKSpriteNode(imageNamed: "Button")
        okButton.position = CGPoint(x: self.size.width * 0.25, y: self.size.height / 2.0 - scoreCard.size.height / 2.0 - kLabelYOffset - okButton.size.height / 2.0)
        okButton.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(okButton)
        
        let ok:SKSpriteNode = SKSpriteNode(imageNamed: "OK")
        ok.position = CGPointZero
        ok.zPosition = Layer.LayerUI.floatValue()
        okButton.addChild(ok);
        
        let shareButton:SKSpriteNode = SKSpriteNode(imageNamed: "Button")
        shareButton.position = CGPoint(x: self.size.width * 0.75, y: self.size.height / 2.0 - scoreCard.size.height / 2.0 - kLabelYOffset - shareButton.size.height / 2.0)
        shareButton.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(shareButton)
        
        let share:SKSpriteNode = SKSpriteNode(imageNamed: "Share")
        share.position = CGPointZero
        share.zPosition = Layer.LayerUI.floatValue()
        shareButton.addChild(share);
        
        gameOver.setScale(0)
        gameOver.alpha = 0
        
        let group:SKAction = SKAction.group([
            SKAction.fadeInWithDuration(kAnimationDelay),
            SKAction.scaleTo(1.0, duration: kAnimationDelay)
        ])
        group.timingMode = SKActionTimingMode.EaseInEaseOut
        gameOver.runAction(SKAction.sequence([
            SKAction.waitForDuration(kAnimationDelay),
            group
        ]))
        
        scoreCard.position = CGPoint(x: self.size.width / 2.0, y: -self.size.height / 2.0)
        let moveTo:SKAction = SKAction.moveTo(CGPoint(x:self.size.width / 2.0, y: self.size.height / 2.0), duration: kAnimationDelay)
        scoreCard.runAction(SKAction.sequence([
            SKAction.waitForDuration(kAnimationDelay * 2.0),
            moveTo
        ]))
        
        okButton.alpha = 0
        shareButton.alpha = 0
        let fadeIn:SKAction = SKAction.sequence([
            SKAction.waitForDuration(kAnimationDelay * 3.0),
            SKAction.fadeInWithDuration(kAnimationDelay)
        ])
        okButton.runAction(fadeIn)
        shareButton.runAction(fadeIn)
        
        let pops:SKAction = SKAction.sequence([
            SKAction.waitForDuration(kAnimationDelay),
            popAction!,
            SKAction.waitForDuration(kAnimationDelay),
            popAction!,
            SKAction.waitForDuration(kAnimationDelay),
            popAction!,
            SKAction.runBlock({ () -> Void in
                self.switchToGameOver()
            })
        ])
        self.runAction(pops)
    }
    
    func setupMainMenu() {
        let logo:SKSpriteNode = SKSpriteNode(imageNamed: "Logo")
        logo.position = CGPoint(x: self.size.width / 2.0, y: self.size.height * 0.8)
        logo.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(logo)
        
        // Play button
        let playButton:SKSpriteNode = SKSpriteNode(imageNamed: "Button")
        playButton.position = CGPoint(x: self.size.width * 0.25, y: self.size.height * 0.25)
        playButton.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(playButton)
        
        let play:SKSpriteNode = SKSpriteNode(imageNamed: "Play")
        play.position = CGPointZero
        playButton.addChild(play)
        
        // Rate button
        let rateButton:SKSpriteNode = SKSpriteNode(imageNamed: "Button")
        rateButton.position = CGPoint(x: self.size.width * 0.75, y: self.size.height * 0.25)
        rateButton.zPosition = Layer.LayerUI.floatValue()
        worldNode.addChild(rateButton)
        
        let rate:SKSpriteNode = SKSpriteNode(imageNamed: "Rate")
        rate.position = CGPointZero
        rateButton.addChild(rate)
    }
    
    func setupPlayerAnimations() {
        // Fly animation
        var flyTextures = Array<SKTexture>()
        for (var i:Int = 0; i < 4; ++i) {
            flyTextures.append(SKTexture(imageNamed: String("Bird"+String(i))))
        }
        
        for (var i:Int = 2; i >= 0; --i) {
            flyTextures.append(SKTexture(imageNamed: String("Bird"+String(i))))
        }
        
        let flyAnimation:SKAction = SKAction.animateWithTextures(flyTextures as [SKTexture], timePerFrame: 0.07)
        player!.runAction(SKAction.repeatActionForever(flyAnimation))
    }
    
    //MARK: - Gameplay
    
    func createObstacle() -> SKSpriteNode {
        let obstacle:SKSpriteNode = SKSpriteNode(imageNamed: "Wall")
        obstacle.zPosition = Layer.LayerObstacle.floatValue()
        
        let offsetX:CGFloat = obstacle.size.width * obstacle.anchorPoint.x
        let offsetY:CGFloat = obstacle.size.height * obstacle.anchorPoint.y
        
        let path:CGMutablePathRef = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 4-offsetX, 309-offsetY)
        CGPathAddLineToPoint(path, nil, 16-offsetX, 315-offsetY)
        CGPathAddLineToPoint(path, nil, 40-offsetX, 315-offsetY)
        CGPathAddLineToPoint(path, nil, 52-offsetX, 305-offsetY)
        CGPathAddLineToPoint(path, nil, 50-offsetX, 1-offsetY)
        CGPathAddLineToPoint(path, nil, 3-offsetX, 1-offsetY)
        CGPathCloseSubpath(path)
        
        obstacle.physicsBody = SKPhysicsBody(polygonFromPath: path)
        //obstacle.attachDebugFrameFromPath(path, color: SKColor.redColor())
        obstacle.physicsBody!.categoryBitMask = EntityCategory.Obstacle.rawValue
        obstacle.physicsBody!.collisionBitMask = 0
        obstacle.physicsBody!.contactTestBitMask = EntityCategory.Player.rawValue
        
        obstacle.userData = NSMutableDictionary()
        
        return obstacle
    }
    
    func spawnObstacle() {
        let bottomObstacle:SKSpriteNode = createObstacle()
        bottomObstacle.name = "BottomObstacle"
        let startX:CGFloat = self.size.width + bottomObstacle.size.width
        let obstacleHalfHeight:CGFloat = bottomObstacle.size.height / 2.0
        
        // Create and position bottom obstacle
        let bottomObstacleMin:CGFloat = (playableStart - obstacleHalfHeight) + playableHeight * kBottomObstacleMinFraction
        let bottomObstacleMax:CGFloat = (playableStart - obstacleHalfHeight) + playableHeight * kBottomObstacleMaxFraction
        bottomObstacle.position = CGPoint(x: startX, y: randomFloatRange(bottomObstacleMin, max: bottomObstacleMax))
        
        // Create and position top obstacle
        let topObstacle:SKSpriteNode = createObstacle()
        topObstacle.name = "TopObstacle"
        topObstacle.zRotation = degreesToRadians(180)
        let topY:CGFloat = bottomObstacle.position.y + obstacleHalfHeight + topObstacle.size.height / 2.0 + (player!.size.height * kGapMultiplier)
        topObstacle.position = CGPoint(x: startX, y: topY)
        
        // Add obstacle to the world
        worldNode.addChild(bottomObstacle)
        worldNode.addChild(topObstacle)
        
        let moveX:CGFloat = self.size.width + topObstacle.size.width * 2.0
        let moveDuration:NSTimeInterval = NSTimeInterval(moveX / kForegroundSpeed)
        let moveAction:SKAction = SKAction.sequence([
            SKAction.moveByX(-moveX, y: 0, duration: moveDuration),
            SKAction.removeFromParent()
            ])
        
        topObstacle.runAction(moveAction)
        bottomObstacle.runAction(moveAction)
    }
    
    func startSpawning() {
        let firstDelay:SKAction = SKAction.waitForDuration(kFirstSpawnDelay)
        let spawn:SKAction = SKAction.runBlock({self.spawnObstacle()})
        let everyDelay:SKAction = SKAction.waitForDuration(kSpawnDelay)
        let spawnSequence:SKAction = SKAction.sequence([everyDelay, spawn])
        let foreverSpawn:SKAction = SKAction.repeatActionForever(spawnSequence)
        let completeSequence:SKAction = SKAction.sequence([firstDelay, foreverSpawn])
        
        self.runAction(completeSequence, withKey: "Spawn")
    }
    
    func stopSpawning() {
        self.removeActionForKey("Spawn")
        
        worldNode.enumerateChildNodesWithName("TopObstacle", 
            usingBlock: { (node:SKNode, stop) -> Void in
                node.removeAllActions()
        })
        worldNode.enumerateChildNodesWithName("BottomObstacle", 
            usingBlock: { (node:SKNode, stop) -> Void in
                node.removeAllActions()
        })
    }
    
    func flapPlayer() {
        playerVelocity = CGPoint(x: 0, y: kImpulse)
        
        jumpSound?.stop()
        jumpSound?.play()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch:UITouch = touches.first!
        let touchLocation:CGPoint = touch.locationInNode(self)
        
        // Yuck....
        switch (gameState) {
            case .MainMenu:
                if (touchLocation.x < (self.size.width * 0.6)) {
                    self.switchToNewGame(GameState.Play)
                }
                else {
                    self.rateApp()
                }
                break
            case .Tutorial:
                switchToPlay()
                break
            case .Play:
                flapPlayer()
                break
            case .Falling:
                
                break
            case .ShowingScore:
                
                break
            case .GameOver:
                if (touchLocation.x < (self.size.width * 0.6)) {
                    switchToNewGame(GameState.MainMenu)
                }
                else {
                    shareScore()
                }
                break
        }
    }
    
    //MARK: - Switch states
    
    func switchToTutorial() {
        gameState = .Tutorial
        
        setupBackground()
        setupMidground()
        setupForeground()
        setupPlayer()
        setupPlayerAnimations()
        setupSounds()
        setupScore()
        setupTutorial()
    }
    
    func switchToPlay() {
        gameState = .Play
        
        worldNode.enumerateChildNodesWithName("Tutorial", 
            usingBlock: { (node:SKNode, stop) -> Void in
                node.runAction(SKAction.sequence([
                        SKAction.fadeOutWithDuration(0.5),
                        SKAction.removeFromParent()
                    ]))
        })
        
        startSpawning()
        
        flapPlayer()
    }
    
    func switchToShowScore() {
        gameState = GameState.ShowingScore
        player!.removeAllActions()
        self.stopSpawning()
        
        self.setupScoreCard()
    }
    
    func switchToFalling() {
        gameState = GameState.Falling
        
        setupGhost()
        
        // Flash white
        let flash:SKSpriteNode = SKSpriteNode(color: SKColor.whiteColor(), size: self.size)
        flash.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.5)
        flash.zPosition = Layer.LayerFlash.floatValue()
        worldNode.addChild(flash)
        flash.runAction(SKAction.sequence([
            SKAction.waitForDuration(0.01),
            SKAction.removeFromParent()
        ]))
        
        deathSound?.play()
        
        player!.removeAllActions()
        self.stopSpawning()
    }
    
    func switchToNewGame(state:GameState) {
        self.runAction(popAction!)
        
        let newScene:SKScene = GameScene(size: self.size, delegate: gameSceneDelegate, state:state)
        let transition:SKTransition = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.5)
        self.view!.presentScene(newScene, transition: transition)
    }
    
    func switchToGameOver() {
        gameState = GameState.GameOver
    }
    
    func switchToMainMenu() {
        gameState = GameState.MainMenu
        
        setupBackground()
        setupMidground()
        setupForeground()
        setupPlayer()
        setupPlayerAnimations()
        setupSounds()
        setupMainMenu()
    }
    
    //MARK: - Special
    
    func shareScore() {
        let urlString:String = "http://itunes.apple.com/id" + String(APP_STORE_ID) + "?mt=8"
        let url:NSURL = NSURL(fileURLWithPath: urlString)
        
        let screenshot:UIImage = gameSceneDelegate.screenShot()
        
        let shareString:String = "Yeah buddy! I just scored " + String(score) + " in Flappy Alex!"
        
        gameSceneDelegate.share(shareString, url: url, image: screenshot)
    }
    
    func rateApp() {
        let urlString:String = "http://itunes.apple.com/id" + String(APP_STORE_ID) + "?mt=8"
        let url:NSURL = NSURL(fileURLWithPath: urlString)
        
        UIApplication.sharedApplication().openURL(url)
    }
    
    //MARK: - Score
    
    func bestScore() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("BestScore")
    }
    
    func setBestScore(newScore:Int) {
        // Don't bother saving this score if it isn't
        // better than the current best score
        if (bestScore() >= newScore) {
            return
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setInteger(newScore, forKey: "BestScore")
        userDefaults.synchronize()
    }
    
    //MARK: - Updates
    
    func checkHitGround() {
        if (hitGround) {
            hitGround = false
            switchToFalling()
        }
    }
    
    func checkHitObstacle() {
        if (hitObstacle) {
            hitObstacle = false
            self.switchToFalling()
        }
    }
    
    func updatePlayer(deltaTick:CGFloat) {
        // Apply gravity
        let gravity = CGPoint(x: 0, y: kGravity)
        playerVelocity.x += (gravity.x * deltaTick)
        playerVelocity.y += (gravity.y * deltaTick)
        
        // Apply velocity
        player!.position.x += (playerVelocity.x * deltaTick)
        player!.position.y += (playerVelocity.y * deltaTick)
        
        // Recorrect the top position
        if (player!.position.y > (self.size.height - player!.size.height / 2.0)) {
            player!.position.y = self.size.height - player!.size.height / 2.0
        }
    }
    
    func updateGhost(deltaTick:CGFloat) {
        playerVelocity.y = kGhostSpeed;
        
        ghost!.position.y += (playerVelocity.y * deltaTick)
        
        if (ghost!.position.y > (self.size.height + ghost!.size.height / 2.0)) {
            self.switchToShowScore()
        }
    }
    
    func updateScore() {
        worldNode.enumerateChildNodesWithName("BottomObstacle", 
            usingBlock: { (node:SKNode, stop) -> Void in
                let obstacle:SKSpriteNode = node as! SKSpriteNode
                let passed:NSNumber? = obstacle.userData!["passed"] as? NSNumber
                
                if (passed != nil && passed!.boolValue == true) {
                    return
                }
                
                if (self.player!.position.x > (obstacle.position.x + obstacle.size.width / 2.0)) {
                    self.score++
                    self.scoreLabel!.text = String(self.score)
                    
                    self.runAction(self.coinAction!)
                    obstacle.userData!["passed"] = true
                }
        })
    }
    
    func updateForeground(deltaTick:CGFloat) {
        let moveAmount = CGPoint(x: -kForegroundSpeed * deltaTick, y: 0)
        
        worldNode.enumerateChildNodesWithName("Foreground", 
            usingBlock: { (node:SKNode, stop) -> Void in
                let foreground:SKSpriteNode = node as! SKSpriteNode
                foreground.position.x += moveAmount.x
                foreground.position.y += moveAmount.y
                
                if (foreground.position.x < -foreground.size.width) {
                    let shiftDistance:CGFloat = foreground.size.width * CGFloat(self.kNumForegrounds)
                    foreground.position.x += shiftDistance
                }
        })
    }
    
    func updateMidground(deltatick:CGFloat) {
        let moveAmount = CGPoint(x: -kForegroundSpeed * kMidgroundSpeedModifier * deltatick, y: 0)
        
        worldNode.enumerateChildNodesWithName("Midground", 
            usingBlock: { (node:SKNode, stop) -> Void in
                let midground:SKSpriteNode = node as! SKSpriteNode
                midground.position.x += moveAmount.x
                midground.position.y += moveAmount.y
                
                if (midground.position.x < -midground.size.width) {
                    let shiftDistance:CGFloat = midground.size.width * CGFloat(self.kNumMidgrounds)
                    midground.position.x += shiftDistance
                }
        })
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let other:SKPhysicsBody = (contact.bodyA.categoryBitMask == EntityCategory.Player.rawValue ? contact.bodyB : contact.bodyA)
        
        if (other.categoryBitMask == EntityCategory.Ground.rawValue) {
            hitGround = true
            return
        }
        if (other.categoryBitMask == EntityCategory.Obstacle.rawValue) {
            hitObstacle = true
            return
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        var deltaTick:CGFloat = 0
        if (lastUpdatedTime != 0) {
            deltaTick = CGFloat(currentTime - lastUpdatedTime)
        }
        
        lastUpdatedTime = currentTime
        
        // Yuck...
        switch (gameState) {
            case .MainMenu:
                updateForeground(deltaTick)
                updateMidground(deltaTick)
                break
            case .Tutorial:
                updateForeground(deltaTick)
                updateMidground(deltaTick)
                break
            case .Play:
                updateForeground(deltaTick)
                updateMidground(deltaTick)
                updatePlayer(deltaTick)
                checkHitGround()
                checkHitObstacle()
                updateScore()
                break
            case .Falling:
                updateGhost(deltaTick)
                checkHitGround()
                break
            case .ShowingScore:
            
                break
            case .GameOver:
            
                break
        }
    }
}
