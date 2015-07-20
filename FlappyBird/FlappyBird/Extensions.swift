//
//  Extensions.swift
//  FlappyBird
//
//  Created by Luke on 24/08/14.
//  Copyright (c) 2014 Teegee. All rights reserved.
//

import Foundation
import SpriteKit

extension SKNode {
    func attachDebugFrameFromPath(path:CGPathRef, color:SKColor) -> SKShapeNode {
        let shape:SKShapeNode = SKShapeNode()
        shape.path = path
        shape.strokeColor = color
        shape.lineWidth = 1.0
        shape.glowWidth = 0.0
        shape.antialiased = false
        addChild(shape)

        return shape
    }
    
    func attachDebugRectWithSize(size:CGSize, color:SKColor) ->SKShapeNode {
        let bodyPath:CGPathRef = CGPathCreateWithRect(CGRect(x: -size.width/2.0, y: -size.height/2.0, width: size.width, height: size.height), nil)
        let shape:SKShapeNode = self.attachDebugFrameFromPath(bodyPath, color: color)
        return shape
    }
    
    func attachDebugLineFromPoint(from:CGPoint, to:CGPoint, color:SKColor) -> SKShapeNode {
        let path:UIBezierPath = UIBezierPath()
        path.moveToPoint(from)
        path.addLineToPoint(to)
        return attachDebugFrameFromPath(path.CGPath, color:color)
    }
}