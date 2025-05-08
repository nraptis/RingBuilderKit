//
//  RingBuilderWeightSegment.swift
//  RingBuilderKit
//
//  Created by Nicholas Raptis on 5/8/25.
//

import Foundation
import MathKit

class RingBuilderWeightSegment: MathKit.PrecomputedLineSegment {
    
    var isIllegal = false
    var isBucketed = false
    var isVisited = false
    
    var x1: Float = 0.0
    var y1: Float = 0.0
    var x2: Float = 0.0
    var y2: Float = 0.0
    
    var controlIndex1 = 0
    var controlIndex2 = 0
    
    
    var centerX: Float = 0.0
    var centerY: Float = 0.0
    
    var directionX = Float(0.0)
    var directionY = Float(-1.0)
    
    var normalX = Float(1.0)
    var normalY = Float(0.0)
    
    var lengthSquared = Float(1.0)
    var length = Float(1.0)
    
    var directionAngle = Float(0.0)
    var normalAngle = Float(0.0)
    
    var storedDistance = Float(0.0)
    
}
