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
    
    override init(size: CGSize) {        
        super.init(size:size)
        
        // Step 5: Add the root note to the scene
        self.addChild(worldNode)
        
        setupBackground()
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
        
    }
    
    // Step 7: Setup foreground and midground
        
    
    override func update(currentTime: NSTimeInterval) {
        
    }
}
