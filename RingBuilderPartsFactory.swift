//
//  RingBuilderPartsFactory.swift
//  RingBuilderKit
//
//  Created by Nicholas Raptis on 5/8/25.
//

import Foundation
import MathKit

public class RingBuilderPartsFactory {
    
    public nonisolated(unsafe) static let shared = RingBuilderPartsFactory()
    
    private init() {
        
    }
    
    public func dispose() {
        ringBuilderWeightPoints.removeAll(keepingCapacity: false)
        ringBuilderWeightPointCount = 0
        
        ringBuilderWeightSegments.removeAll(keepingCapacity: false)
        ringBuilderWeightSegmentCount = 0
    }
    
    private var ringBuilderWeightPoints = [RingBuilderWeightPoint]()
    var ringBuilderWeightPointCount = 0
    func depositRingBuilderWeightPoint(_ ringBuilderWeightPoint: RingBuilderWeightPoint) {
        while ringBuilderWeightPoints.count <= ringBuilderWeightPointCount {
            ringBuilderWeightPoints.append(ringBuilderWeightPoint)
        }
        ringBuilderWeightPoints[ringBuilderWeightPointCount] = ringBuilderWeightPoint
        ringBuilderWeightPointCount += 1
    }
    func withdrawRingBuilderWeightPoint() -> RingBuilderWeightPoint {
        if ringBuilderWeightPointCount > 0 {
            ringBuilderWeightPointCount -= 1
            return ringBuilderWeightPoints[ringBuilderWeightPointCount]
        }
        return RingBuilderWeightPoint()
    }
    
    private var ringBuilderWeightSegments = [RingBuilderWeightSegment]()
    var ringBuilderWeightSegmentCount = 0
    func depositRingBuilderWeightSegment(_ ringBuilderWeightSegment: RingBuilderWeightSegment) {
        ringBuilderWeightSegment.isIllegal = false
        ringBuilderWeightSegment.isBucketed = false // This may well have been the midding nugget
        
        while ringBuilderWeightSegments.count <= ringBuilderWeightSegmentCount {
            ringBuilderWeightSegments.append(ringBuilderWeightSegment)
        }
        ringBuilderWeightSegments[ringBuilderWeightSegmentCount] = ringBuilderWeightSegment
        ringBuilderWeightSegmentCount += 1
    }
    func withdrawRingBuilderWeightSegment() -> RingBuilderWeightSegment {
        if ringBuilderWeightSegmentCount > 0 {
            ringBuilderWeightSegmentCount -= 1
            return ringBuilderWeightSegments[ringBuilderWeightSegmentCount]
        }
        return RingBuilderWeightSegment()
    }
}
