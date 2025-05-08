//
//  RingBuilderWeightPointInsidePolygonBucket.swift
//  RingBuilderKit
//
//  Created by Nicholas Raptis on 5/8/25.
//

import Foundation

final class RingBuilderWeightPointInsidePolygonBucket {
    
    private class RingBuilderWeightPointInsidePolygonBucketNode {
        
        var ringBuilderWeightSegments = [RingBuilderWeightSegment]()
        var ringBuilderWeightSegmentCount = 0
        
        func remove(_ ringBuilderWeightSegment: RingBuilderWeightSegment) {
            for checkIndex in 0..<ringBuilderWeightSegmentCount {
                if ringBuilderWeightSegments[checkIndex] === ringBuilderWeightSegment {
                    remove(checkIndex)
                    return
                }
            }
        }
        
        func remove(_ index: Int) {
            if index >= 0 && index < ringBuilderWeightSegmentCount {
                let ringBuilderWeightSegmentCount1 = ringBuilderWeightSegmentCount - 1
                var ringBuilderWeightSegmentIndex = index
                while ringBuilderWeightSegmentIndex < ringBuilderWeightSegmentCount1 {
                    ringBuilderWeightSegments[ringBuilderWeightSegmentIndex] = ringBuilderWeightSegments[ringBuilderWeightSegmentIndex + 1]
                    ringBuilderWeightSegmentIndex += 1
                }
                ringBuilderWeightSegmentCount -= 1
            }
        }
        
        func add(_ ringBuilderWeightSegment: RingBuilderWeightSegment) {
            while ringBuilderWeightSegments.count <= ringBuilderWeightSegmentCount {
                ringBuilderWeightSegments.append(ringBuilderWeightSegment)
            }
            ringBuilderWeightSegments[ringBuilderWeightSegmentCount] = ringBuilderWeightSegment
            ringBuilderWeightSegmentCount += 1
        }
        
    }
    
    private static let countH = 24
    
    private var nodes = [RingBuilderWeightPointInsidePolygonBucketNode]()
    private var gridX: [Float]
    
    init() {
        gridX = [Float](repeating: 0.0, count: Self.countH)
        var x = 0
        while x < Self.countH {
            let node = RingBuilderWeightPointInsidePolygonBucketNode()
            nodes.append(node)
            x += 1
        }
    }
    
    func reset() {
        var x = 0
        while x < Self.countH {
            nodes[x].ringBuilderWeightSegmentCount = 0
            x += 1
        }
    }
    
    func build(ringBuilderWeightSegments: [RingBuilderWeightSegment], ringBuilderWeightSegmentCount: Int) {
        
        reset()
        
        guard ringBuilderWeightSegmentCount > 0 else {
            return
        }
        
        let referenceRingBuilderWeightSegment = ringBuilderWeightSegments[0]
        
        var minX = min(referenceRingBuilderWeightSegment.x1, referenceRingBuilderWeightSegment.x2)
        var maxX = max(referenceRingBuilderWeightSegment.x1, referenceRingBuilderWeightSegment.x2)
        
        var ringBuilderWeightSegmentIndex = 1
        while ringBuilderWeightSegmentIndex < ringBuilderWeightSegmentCount {
            let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
            
            minX = min(minX, ringBuilderWeightSegment.x1); minX = min(minX, ringBuilderWeightSegment.x2)
            maxX = max(maxX, ringBuilderWeightSegment.x1); maxX = max(maxX, ringBuilderWeightSegment.x2)
            
            ringBuilderWeightSegmentIndex += 1
        }
        
        minX -= 1.0
        maxX += 1.0
        
        var x = 0
        while x < Self.countH {
            let percent = Float(x) / Float(Self.countH - 1)
            gridX[x] = minX + (maxX - minX) * percent
            x += 1
        }
        
        for ringBuilderWeightSegmentIndex in 0..<ringBuilderWeightSegmentCount {
            let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
            
            let _minX = min(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
            let _maxX = max(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
            
            let lowerBoundX = lowerBoundX(value: _minX)
            let upperBoundX = upperBoundX(value: _maxX)
            
            x = lowerBoundX
            while x <= upperBoundX {
                nodes[x].add(ringBuilderWeightSegment)
                x += 1
            }
        }
    }
    
    func query(x: Float, y: Float) -> Bool {
        var result = false
        let indexX = lowerBoundX(value: x)
        if indexX < Self.countH {
            for ringBuilderWeightSegmentIndex in 0..<nodes[indexX].ringBuilderWeightSegmentCount {
                let ringBuilderWeightSegment = nodes[indexX].ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                let x1: Float
                let y1: Float
                let x2: Float
                let y2: Float
                if ringBuilderWeightSegment.x1 < ringBuilderWeightSegment.x2 {
                    x1 = ringBuilderWeightSegment.x1
                    y1 = ringBuilderWeightSegment.y1
                    x2 = ringBuilderWeightSegment.x2
                    y2 = ringBuilderWeightSegment.y2
                } else {
                    x1 = ringBuilderWeightSegment.x2
                    y1 = ringBuilderWeightSegment.y2
                    x2 = ringBuilderWeightSegment.x1
                    y2 = ringBuilderWeightSegment.y1
                }
                if x > x1 && x <= x2 {
                    if (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1) < 0.0 {
                        result = !result
                    }
                }
            }
        }
        return result
    }
    
    private func lowerBoundX(value: Float) -> Int {
        var start = 0
        var end = Self.countH
        while start != end {
            let mid = (start + end) >> 1
            if value > gridX[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return start
    }
    
    private func upperBoundX(value: Float) -> Int {
        var start = 0
        var end = Self.countH
        while start != end {
            let mid = (start + end) >> 1
            if value >= gridX[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return min(start, Self.countH - 1)
    }
}
