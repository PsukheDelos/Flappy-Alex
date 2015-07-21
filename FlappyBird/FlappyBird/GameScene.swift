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
    
    // Step 9: Add gameplay constants
    
    
    override init(size: CGSize) {        
        super.init(size:size)
        
        // Step 5: Add the root note to the scene
        self.addChild(worldNode)
        
        setupBackground()
        setupMidground()
        setupForeground()
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
    }
    
    // Step 7: Setup foreground and midground
    // Step 10: Modify midground and foreground to include some tiles
    func setupMidground() {
        let midground = SKSpriteNode(imageNamed: "Midground")
        midground.anchorPoint = CGPoint(x: 0, y: 1)
        midground.position = CGPoint(x: 0, y: self.size.height)
        midground.zPosition = Layer.LayerMidground.floatValue()
        midground.name = "Midground"
        worldNode.addChild(midground)
    }
    
    func setupForeground() {
        let foreground = SKSpriteNode(imageNamed: "Ground")
        foreground.anchorPoint = CGPoint(x: 0, y: 1)
        foreground.position = CGPoint(x: 0, y: playableStart)
        foreground.zPosition = Layer.LayerForeground.floatValue()
        foreground.name = "Foreground"
        worldNode.addChild(foreground)
    }
    
    // Step 11: Update the foreground and midground
    
    
    override func update(currentTime: NSTimeInterval) {
        // Step 12: Calculate the deltaTick and update tiles
        
    }
}
