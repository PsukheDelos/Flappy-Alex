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
    
    
    override init(size: CGSize) {        
        super.init(size:size)
        
        // Step 5: Add the root note to the scene
        self.addChild(worldNode)
        
        setupBackground()
        setupMidground()
        setupForeground()
        setupPlayer()
        
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
    
    
    // Step 17: Spawn complete obstacle
    
    
    // Step 18: Handle spawning intervals
    
    
    override func update(currentTime: NSTimeInterval) {
        // Step 12: Calculate the deltaTick and update tiles
        var deltaTick:CGFloat = 0
        if (lastUpdatedTime != 0) {
            deltaTick = CGFloat(currentTime - lastUpdatedTime)
        }
        
        lastUpdatedTime = currentTime
        
        updateForeground(deltaTick)
        updateMidground(deltaTick)
    }
}
