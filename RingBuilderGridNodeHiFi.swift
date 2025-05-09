//
//  RingBuilderGridNodeHiFi.swift
//  Manifold
//
//  Created by Nick Raptis on 8/4/24.
//

import Foundation
import MathKit

struct RingBuilderGridNodeHiFi {
    
    typealias Point = Math.Point
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    var interpX = Float(0.0)
    var interpY = Float(0.0)
    
    var checkX = Float(0.0)
    var checkY = Float(0.0)
    
    var isInside = false
    
    var isIncluded = false
    
    var isChosen = false
    var isVisited = false
    var isEroded = false
    var isDilated = false
    
    var distanceFromCentroid = Float(0.0)
    var distanceFromCentroidPercent = Float(0.0)
    
    var distanceFromEdge = Float(0.0)
    var distanceFromEdgePercent = Float(0.0)
    
    var gravityAdjustmentFactor = Float(0.0)
    
    var groupIndex = -1
    
    var point: Point {
        Point(x: x,
              y: y)
    }
}
