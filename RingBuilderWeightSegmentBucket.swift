//
//  RingBuilderWeightSegmentBucket.swift
//  RingBuilderKit
//
//  Created by Nicholas Raptis on 5/8/25.
//

import Foundation

final class RingBuilderWeightSegmentBucket {
    
    private class RingBuilderWeightSegmentBucketNode {
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
    private static let countV = 24
    
    private var grid = [[RingBuilderWeightSegmentBucketNode]]()
    private var gridX: [Float]
    private var gridY: [Float]
    
    private(set) var ringBuilderWeightSegments: [RingBuilderWeightSegment]
    private(set) var ringBuilderWeightSegmentCount = 0
    
    init() {
        
        gridX = [Float](repeating: 0.0, count: Self.countH)
        gridY = [Float](repeating: 0.0, count: Self.countV)
        ringBuilderWeightSegments = [RingBuilderWeightSegment]()
        
        var x = 0
        while x < Self.countH {
            var column = [RingBuilderWeightSegmentBucketNode]()
            var y = 0
            while y < Self.countV {
                let node = RingBuilderWeightSegmentBucketNode()
                column.append(node)
                y += 1
            }
            grid.append(column)
            x += 1
        }
    }
    
    func reset() {
        var x = 0
        var y = 0
        while x < Self.countH {
            y = 0
            while y < Self.countV {
                grid[x][y].ringBuilderWeightSegmentCount = 0
                y += 1
            }
            x += 1
        }
        
        ringBuilderWeightSegmentCount = 0
    }
    
    func build(ringBuilderWeightSegments: [RingBuilderWeightSegment], ringBuilderWeightSegmentCount: Int) {
        
        reset()
        
        guard ringBuilderWeightSegmentCount > 0 else {
            return
        }
        
        let referenceRingBuilderWeightSegment = ringBuilderWeightSegments[0]
        
        var minX = min(referenceRingBuilderWeightSegment.x1, referenceRingBuilderWeightSegment.x2)
        var maxX = max(referenceRingBuilderWeightSegment.x1, referenceRingBuilderWeightSegment.x2)
        var minY = min(referenceRingBuilderWeightSegment.y1, referenceRingBuilderWeightSegment.y2)
        var maxY = max(referenceRingBuilderWeightSegment.y1, referenceRingBuilderWeightSegment.y2)
        
        var ringBuilderWeightSegmentIndex = 1
        while ringBuilderWeightSegmentIndex < ringBuilderWeightSegmentCount {
            let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
            minX = min(minX, ringBuilderWeightSegment.x1); minX = min(minX, ringBuilderWeightSegment.x2)
            maxX = max(maxX, ringBuilderWeightSegment.x1); maxX = max(maxX, ringBuilderWeightSegment.x2)
            minY = min(minY, ringBuilderWeightSegment.y1); minY = min(minY, ringBuilderWeightSegment.y2)
            maxY = max(maxY, ringBuilderWeightSegment.y1); maxY = max(maxY, ringBuilderWeightSegment.y2)
            ringBuilderWeightSegmentIndex += 1
        }
        
        minX -= 32.0
        maxX += 32.0
        minY -= 32.0
        maxY += 32.0
        
        var x = 0
        while x < Self.countH {
            let percent = Float(x) / Float(Self.countH - 1)
            gridX[x] = minX + (maxX - minX) * percent
            x += 1
        }
        
        var y = 0
        while y < Self.countV {
            let percent = Float(y) / Float(Self.countV - 1)
            gridY[y] = minY + (maxY - minY) * percent
            y += 1
        }
        
        for ringBuilderWeightSegmentIndex in 0..<ringBuilderWeightSegmentCount {
            let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
            
            let _minX = min(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
            let _maxX = max(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
            let _minY = min(ringBuilderWeightSegment.y1, ringBuilderWeightSegment.y2)
            let _maxY = max(ringBuilderWeightSegment.y1, ringBuilderWeightSegment.y2)
            
            let lowerBoundX = lowerBoundX(value: _minX)
            let upperBoundX = upperBoundX(value: _maxX)
            let lowerBoundY = lowerBoundY(value: _minY)
            let upperBoundY = upperBoundY(value: _maxY)
            
            x = lowerBoundX
            while x <= upperBoundX {
                y = lowerBoundY
                while y <= upperBoundY {
                    grid[x][y].add(ringBuilderWeightSegment)
                    y += 1
                }
                x += 1
            }
        }
    }
    
    func remove(ringBuilderWeightSegment: RingBuilderWeightSegment) {
        let _minX = min(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
        let _maxX = max(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
        let _minY = min(ringBuilderWeightSegment.y1, ringBuilderWeightSegment.y2)
        let _maxY = max(ringBuilderWeightSegment.y1, ringBuilderWeightSegment.y2)
        
        let lowerBoundX = lowerBoundX(value: _minX)
        let upperBoundX = upperBoundX(value: _maxX)
        let lowerBoundY = lowerBoundY(value: _minY)
        let upperBoundY = upperBoundY(value: _maxY)
        
        var x = 0
        var y = 0
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                grid[x][y].remove(ringBuilderWeightSegment)
                y += 1
            }
            x += 1
        }
    }
    
    func add(ringBuilderWeightSegment: RingBuilderWeightSegment) {
            
        let _minX = min(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
        let _maxX = max(ringBuilderWeightSegment.x1, ringBuilderWeightSegment.x2)
        let _minY = min(ringBuilderWeightSegment.y1, ringBuilderWeightSegment.y2)
        let _maxY = max(ringBuilderWeightSegment.y1, ringBuilderWeightSegment.y2)
        
        let lowerBoundX = lowerBoundX(value: _minX)
        let upperBoundX = upperBoundX(value: _maxX)
        let lowerBoundY = lowerBoundY(value: _minY)
        let upperBoundY = upperBoundY(value: _maxY)
        
        var x = 0
        var y = 0
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                grid[x][y].add(ringBuilderWeightSegment)
                y += 1
            }
            x += 1
        }
    }
    
    func query(ringBuilderWeightSegment: RingBuilderWeightSegment) {
        let x1 = ringBuilderWeightSegment.x1
        let y1 = ringBuilderWeightSegment.y1
        let x2 = ringBuilderWeightSegment.x2
        let y2 = ringBuilderWeightSegment.y2
        query(minX: min(x1, x2),
              maxX: max(x1, x2),
              minY: min(y1, y2),
              maxY: max(y1, y2))
    }
    
    func query(ringBuilderWeightSegment: RingBuilderWeightSegment, padding: Float) {
        let x1 = ringBuilderWeightSegment.x1
        let y1 = ringBuilderWeightSegment.y1
        let x2 = ringBuilderWeightSegment.x2
        let y2 = ringBuilderWeightSegment.y2
        query(minX: min(x1, x2) - padding,
              maxX: max(x1, x2) + padding,
              minY: min(y1, y2) - padding,
              maxY: max(y1, y2) + padding)
    }
    
    func query(minX: Float, maxX: Float, minY: Float, maxY: Float) {
        
        ringBuilderWeightSegmentCount = 0
        
        let lowerBoundX = lowerBoundX(value: minX)
        var upperBoundX = upperBoundX(value: maxX)
        let lowerBoundY = lowerBoundY(value: minY)
        var upperBoundY = upperBoundY(value: maxY)
        
        if upperBoundX >= Self.countH {
            upperBoundX = Self.countH - 1
        }
        
        if upperBoundY >= Self.countV {
            upperBoundY = Self.countV - 1
        }
        
        var x = 0
        var y = 0
        
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                for ringBuilderWeightSegmentIndex in 0..<grid[x][y].ringBuilderWeightSegmentCount {
                    grid[x][y].ringBuilderWeightSegments[ringBuilderWeightSegmentIndex].isBucketed = false
                }
                y += 1
            }
            x += 1
        }
        
        x = lowerBoundX
        while x <= upperBoundX {
            y = lowerBoundY
            while y <= upperBoundY {
                for ringBuilderWeightSegmentIndex in 0..<grid[x][y].ringBuilderWeightSegmentCount {
                    let ringBuilderWeightSegment = grid[x][y].ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                    if ringBuilderWeightSegment.isBucketed == false {
                        ringBuilderWeightSegment.isBucketed = true
                        
                        while ringBuilderWeightSegments.count <= ringBuilderWeightSegmentCount {
                            ringBuilderWeightSegments.append(ringBuilderWeightSegment)
                        }
                        ringBuilderWeightSegments[ringBuilderWeightSegmentCount] = ringBuilderWeightSegment
                        ringBuilderWeightSegmentCount += 1
                    }
                }
                y += 1
            }
            x += 1
        }
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
    
    func lowerBoundY(value: Float) -> Int {
        var start = 0
        var end = Self.countV
        while start != end {
            let mid = (start + end) >> 1
            if value > gridY[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return start
        
    }
    
    func upperBoundY(value: Float) -> Int {
        var start = 0
        var end = Self.countV
        while start != end {
            let mid = (start + end) >> 1
            if value >= gridY[mid] {
                start = mid + 1
            } else {
                end = mid
            }
        }
        return min(start, Self.countV - 1)
    }
}
