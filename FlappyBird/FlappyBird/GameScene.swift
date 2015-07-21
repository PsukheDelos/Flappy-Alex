//
//  GameScene.swift
//  FlappyBird
//
//  Created by Luke on 20/08/14.
//  Copyright (c) 2014 Teegee. All rights reserved.
//

import SpriteKit
import AVFoundation

// Step 3: Layers
enum Layer:Int {
    case LayerBackground = 1, LayerMidground, LayerObstacle, LayerForeground, LayerPlayer, LayerFlash, LayerUI
    
    func floatValue() -> CGFloat {
        return CGFloat(self.rawValue)
    }
}

// Step 20: Collision masks
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
    
    // Step 2: Create our root node for the scene graph
    var worldNode:SKNode = SKNode()
    
    // Step 8: Add the playableStart variable
    var playableStart:CGFloat = 0
    var playableHeight : CGFloat = 0.0
    
    // Step 9: Add gameplay constants
    var lastUpdatedTime:NSTimeInterval = 0
    
    // Gameplay - Foreground moving
    let kNumForegrounds:Int = 2
    let kForegroundSpeed:CGFloat = 150;
    
    // Gameplay - Midground moving
    let kNumMidgrounds:Int = 2
    let kMidgroundSpeedModifier:CGFloat = 0.5
    
    // Step 13: Create player variables
    var player:SKSpriteNode?
    
    // Step 15: Create obstacle variables
    // Gameplay - Obstacle positioning
    let kGapMultiplier:CGFloat = 3.5
    let kBottomObstacleMinFraction:CGFloat = 0.1
    let kBottomObstacleMaxFraction:CGFloat = 0.6
    
    // Gameplay - Obstacle spawn timing
    let kFirstSpawnDelay:Double = 1.5
    let kSpawnDelay:Double = 1.5
    
    // Step 19: Physics variables
    var hitObstacle:Bool = false
    
    // Gameplay - Player movement
    let kGravity:CGFloat = -1300.0
    let kImpulse:CGFloat = 400
    var playerVelocity : CGPoint = CGPoint(x: 0, y: 0)
    
    // Step 29: Ghost variables
    
    
    override init(size: CGSize) {        
        super.init(size:size)
        
        // Step 21: Physics world
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        
        // Step 5: Add the root note to the scene
        self.addChild(worldNode)
        
        setupBackground()
        setupMidground()
        setupForeground()
        setupPlayer()
        
        startSpawning()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Step 4: Setup background
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "Background")
        background.anchorPoint = CGPoint(x:0.5, y:1.0)
        background.position = CGPoint(x:self.size.width / 2.0, y:self.size.height);
        background.zPosition = Layer.LayerBackground.floatValue()
        worldNode.addChild(background)
        
        // Step 9: Move the foreground to the correct position
        playableStart = self.size.height - background.size.height
        playableHeight = background.size.height
        
        // Step 23: Add ground physics
        let lowerLeft:CGPoint = CGPoint(x: 0, y: playableStart)
        let lowerRight:CGPoint = CGPoint(x: self.size.width, y: playableStart)
        
        self.physicsBody = SKPhysicsBody(edgeFromPoint: lowerLeft, toPoint: lowerRight)
        //self.attachDebugLineFromPoint(lowerLeft, to: lowerRight, color: UIColor.redColor())
        
        self.physicsBody!.categoryBitMask = EntityCategory.Ground.rawValue
        self.physicsBody!.collisionBitMask = 0
        self.physicsBody!.contactTestBitMask = EntityCategory.Player.rawValue
    }
    
    // Step 7: Setup foreground and midground
    // Step 10: Modify midground and foreground to include some tiles
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
    
    // Step 11: Update the foreground and midground
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
    
    // Step 14: Create the player
    func setupPlayer() {
        player = SKSpriteNode(imageNamed: "Bird0")
        player!.position = CGPoint(x: self.size.width * 0.2, y: playableHeight * 0.4 + playableStart)
        player!.zPosition = Layer.LayerPlayer.floatValue()
        worldNode.addChild(player!)
        
        // Step 22: Add player physics
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
        
        setupPlayerAnimations()
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
    
    // Step 16: Create single obstacle
    func createObstacle() -> SKSpriteNode {
        let obstacle:SKSpriteNode = SKSpriteNode(imageNamed: "Wall")
        obstacle.zPosition = Layer.LayerObstacle.floatValue()
        
        // Step 24: Add obstacle phyics
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
    
    // Step 25: Add begin contact
    func didBeginContact(contact: SKPhysicsContact) {
        let other:SKPhysicsBody = (contact.bodyA.categoryBitMask == EntityCategory.Player.rawValue ? contact.bodyB : contact.bodyA)
        
        if (other.categoryBitMask == EntityCategory.Ground.rawValue) {
            hitObstacle = true
            stopSpawning()
            return
        }
        if (other.categoryBitMask == EntityCategory.Obstacle.rawValue) {
            hitObstacle = true
            stopSpawning()
            return
        }
    }
    
    // Step 17: Spawn complete obstacle
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
    
    // Step 18: Handle spawning intervals
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
    
    // Step 27: Update the player
    
    // Step 28: Handle player input
    
    // Step 30: Create the ghost
    
    // Step 31: Spawn the ghost
    
    // Step 32: Update the ghost
    
    override func update(currentTime: NSTimeInterval) {
        // Step 12: Calculate the deltaTick and update tiles
        var deltaTick:CGFloat = 0
        if (lastUpdatedTime != 0) {
            deltaTick = CGFloat(currentTime - lastUpdatedTime)
        }
        
        lastUpdatedTime = currentTime
        
        // Step 26: Change so that the game stops updating after a hit
        // Step 33: Change to final update
        if (!hitObstacle) {
            updateForeground(deltaTick)
            updateMidground(deltaTick)
        }
    }
}
