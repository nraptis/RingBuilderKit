//
//  RingBuilderGridNodeLoFi.swift
//  Manifold
//
//  Created by Nick Raptis on 8/3/24.
//

import Foundation
import MathKit

class RingBuilderGridNodeLoFi {
    
    typealias Point = Math.Point
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    //var isInside = false
    
    var distanceFromEdge = Float(0.0)
    
    var point: Point {
        Point(x: x,
              y: y)
    }
    
    var ringBuilderWeightSegments = [RingBuilderWeightSegment]()
    var ringBuilderWeightSegmentCount = 0
    func addRingBuilderWeightSegment(_ ringBuilderWeightSegment: RingBuilderWeightSegment) {
        while ringBuilderWeightSegments.count <= ringBuilderWeightSegmentCount {
            ringBuilderWeightSegments.append(ringBuilderWeightSegment)
        }
        ringBuilderWeightSegments[ringBuilderWeightSegmentCount] = ringBuilderWeightSegment
        ringBuilderWeightSegmentCount += 1
    }
    
    func removeAllRingBuilderWeightSegments() {
        ringBuilderWeightSegmentCount = 0
    }
    
}
