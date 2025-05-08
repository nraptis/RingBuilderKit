//
//  RingBuilderGrid.swift
//  Manifold
//
//  Created by Nick Raptis on 8/3/24.
//

import Foundation
import MathKit

class RingBuilderGrid {
    
    static let fidelityLoFi = Float(5)
    static let stepsHiFi = 5
    
    static let segmentsPerNode = 7
    
    let edgePointList = IntPointList()
    
    var countHLoFi = 0
    var countVLoFi = 0
    var gridLoFi = [[RingBuilderGridNodeLoFi]]()
    var gridLoFiStartH = [Int]()
    var gridLoFiStartV = [Int]()
    var gridLoFiCeilingH = [Int]()
    var gridLoFiCeilingV = [Int]()
    var gridLoFiFloorH = [Int]()
    var gridLoFiFloorV = [Int]()
    
    var countHHiFi = 0
    var countVHiFi = 0
    var gridHiFi = [[RingBuilderGridNodeHiFi]]()
    
    var maximumDistanceFromEdgeHiFi = Float(0.0)
    
    var centroidXHiFi = Float(0.0)
    var centroidYHiFi = Float(0.0)
    
    var groupIndex = -1
    
    var stackX = [Int]()
    var stackY = [Int]()
    var stackCount = 0
    
    var tempWeightSegments = [RingBuilderWeightSegment]()
    var tempWeightSegmentCount = 0
    func addTempWeightSegment(_ ringBuilderWeightSegment: RingBuilderWeightSegment) {
        while tempWeightSegments.count <= tempWeightSegmentCount {
            tempWeightSegments.append(ringBuilderWeightSegment)
        }
        tempWeightSegments[tempWeightSegmentCount] = ringBuilderWeightSegment
        tempWeightSegmentCount += 1
    }
    
    func removeAllTempWeightSegments() {
        tempWeightSegmentCount = 0
    }
    
    func clear() {
        
        edgePointList.removeAll(keepingCapacity: true)
        
        gridLoFi.removeAll()
        gridHiFi.removeAll()
        
        maximumDistanceFromEdgeHiFi = Float(0.0)
        
        centroidXHiFi = Float(0.0)
        centroidYHiFi = Float(0.0)
        
        gridLoFiStartH.removeAll()
        gridLoFiStartV.removeAll()
        gridLoFiCeilingH.removeAll()
        gridLoFiCeilingV.removeAll()
        gridLoFiFloorH.removeAll()
        gridLoFiFloorV.removeAll()
        
        removeAllTempWeightSegments()
    }
    
    func sizeGridAndCalculateNodePositionsLoFi(minX: Float, minY: Float, maxX: Float, maxY: Float) async {
        
        let _minX = minX - 10.0
        let _minY = minY - 10.0
        let _maxX = maxX + 10.0
        let _maxY = maxY + 10.0
        
        let centerX = Float(Int((minX + maxX) * 0.5))
        let centerY = Float(Int((minY + maxY) * 0.5))
        
        var __minX = centerX
        while __minX > _minX { __minX -= Self.fidelityLoFi }
        
        var countHLoFi = 0
        while true {
            let __maxX = __minX + Float(countHLoFi) * Self.fidelityLoFi
            if __maxX >= _maxX {
                countHLoFi += 1
                break
            }
            countHLoFi += 1
        }
        
        var __minY = centerY
        while __minY > _minY { __minY -= Self.fidelityLoFi }
        
        var countVLoFi = 0
        while true {
            let __maxY = __minY + Float(countVLoFi) * Self.fidelityLoFi
            if __maxY >= _maxY {
                countVLoFi += 1
                break
            }
            countVLoFi += 1
        }
        
        while gridLoFi.count < countHLoFi {
            gridLoFi.append([RingBuilderGridNodeLoFi]())
        }
        var indexH = 0
        while indexH < countHLoFi {
            while gridLoFi[indexH].count < countVLoFi {
                gridLoFi[indexH].append(.init())
            }
            indexH += 1
        }
        self.countHLoFi = countHLoFi
        self.countVLoFi = countVLoFi
        
        indexH = 0
        while indexH < (countHLoFi - 1) {
            gridLoFiStartH.append(0)
            gridLoFiCeilingH.append(0)
            gridLoFiFloorH.append(0)
            indexH += 1
        }
        
        var indexV = 0
        while indexV < (countVLoFi - 1) {
            gridLoFiStartV.append(0)
            gridLoFiCeilingV.append(0)
            gridLoFiFloorV.append(0)
            indexV += 1
        }
        
        indexV = 0
        while indexV < countVLoFi {
            
            let y = __minY + Float(indexV) * Self.fidelityLoFi
            
            indexH = 0
            while indexH < countHLoFi {
                
                let x = __minX + Float(indexH) * Self.fidelityLoFi
                gridLoFi[indexH][indexV].x = x
                gridLoFi[indexH][indexV].y = y
                indexH += 1
            }
            indexV += 1
        }
    }
    
    func calculateDistanceFromEdgeAndNearSegmentsLoFi(ringBuilderWeightSegments: [RingBuilderWeightSegment],
                                                      ringBuilderWeightSegmentCount: Int) async {
        
        var indexV = 0
        var indexH = 0
        
        while indexV < countVLoFi {
            
            indexH = 0
            while indexH < countHLoFi {
                
                let node = gridLoFi[indexH][indexV]
                
                let x = node.x
                let y = node.y
                
                var bestDistanceSquared = Float(100_000_000.0)
                
                for ringBuilderWeightSegmentsIndex in 0..<ringBuilderWeightSegmentCount {
                    let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentsIndex]
                    let distanceSquared = ringBuilderWeightSegment.distanceSquaredToClosestPoint(x, y)
                    ringBuilderWeightSegment.storedDistance = distanceSquared
                    ringBuilderWeightSegment.isVisited = false
                    if distanceSquared < bestDistanceSquared {
                        bestDistanceSquared = distanceSquared
                    }
                }
                
                node.removeAllRingBuilderWeightSegments()
                
                // 1.) Find the "very lowest distance".
                var lowestDistance = Float(100_000_000.0)
                for ringBuilderWeightSegmentsIndex in 0..<ringBuilderWeightSegmentCount {
                    let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentsIndex]
                    if ringBuilderWeightSegment.storedDistance < lowestDistance {
                        lowestDistance = ringBuilderWeightSegment.storedDistance
                    }
                }
                
                // 2.) Add all segments with "very lowest distance"
                //     only up to "segments per node..."
                for ringBuilderWeightSegmentsIndex in 0..<ringBuilderWeightSegmentCount {
                    let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentsIndex]
                    if ringBuilderWeightSegment.storedDistance == lowestDistance {
                        if node.ringBuilderWeightSegmentCount < Self.segmentsPerNode {
                            node.addRingBuilderWeightSegment(ringBuilderWeightSegment)
                            ringBuilderWeightSegment.isVisited = true
                        }
                    }
                }
                
                // 3.) Repeat while there is
                //     a.) An unvisited node.
                //     b.) Less than "segments per node"
                while true {
                    
                    // 1.) Find the "very lowest distance".
                    lowestDistance = Float(100_000_000.0)
                    for ringBuilderWeightSegmentsIndex in 0..<ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentsIndex]
                        if ringBuilderWeightSegment.isVisited == false {
                            if ringBuilderWeightSegment.storedDistance < lowestDistance {
                                lowestDistance = ringBuilderWeightSegment.storedDistance
                            }
                        }
                    }
                    
                    var isAnyNodeVisited = false
                    
                    // 2.) Add all segments with "very lowest distance"
                    //     only up to "segments per node..."
                    for ringBuilderWeightSegmentsIndex in 0..<ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = ringBuilderWeightSegments[ringBuilderWeightSegmentsIndex]
                        if ringBuilderWeightSegment.storedDistance == lowestDistance {
                            if node.ringBuilderWeightSegmentCount < Self.segmentsPerNode {
                                node.addRingBuilderWeightSegment(ringBuilderWeightSegment)
                                ringBuilderWeightSegment.isVisited = true
                                isAnyNodeVisited = true
                            }
                        }
                    }
                    
                    if isAnyNodeVisited == false { break }
                    if node.ringBuilderWeightSegmentCount >= Self.segmentsPerNode { break }
                }
                
                if bestDistanceSquared > MathKit.Math.epsilon {
                    let distance = sqrtf(bestDistanceSquared)
                    node.distanceFromEdge = distance
                } else {
                    node.distanceFromEdge = 0.0
                }
                
                indexH += 1
            }
            indexV += 1
        }
    }
    
    func sizeGridHiFi() async {
        let countHHiFi = (countHLoFi - 1) * (Self.stepsHiFi) + 1
        let countVHiFi = (countVLoFi - 1) * (Self.stepsHiFi) + 1
        while gridHiFi.count < countHHiFi {
            gridHiFi.append([RingBuilderGridNodeHiFi]())
        }
        var indexH = 0
        while indexH < countHHiFi {
            while gridHiFi[indexH].count < countVHiFi {
                gridHiFi[indexH].append(.init())
            }
            indexH += 1
        }
        self.countHHiFi = countHHiFi
        self.countVHiFi = countVHiFi
    }
    
    func calculateNodeInterpolationHiFi() async {
        
        if countHHiFi > 0 && countVHiFi > 0 {
            var indexV = 0
            var indexH = 0
            
            gridHiFi[0][0].x = gridLoFi[0][0].x
            gridHiFi[0][0].y = gridLoFi[0][0].y
            
            var indexHLoFi = 0
            while indexHLoFi < (countHLoFi - 1) {
                
                let indexHHiFiFloor = indexHLoFi * Self.stepsHiFi
                let indexHHiFiStart = indexHLoFi * Self.stepsHiFi + 1
                let indexHHiFiCeiling = (indexHLoFi + 1) * Self.stepsHiFi
                
                gridLoFiFloorH[indexHLoFi] = indexHHiFiFloor
                gridLoFiStartH[indexHLoFi] = indexHHiFiStart
                gridLoFiCeilingH[indexHLoFi] = indexHHiFiCeiling
                
                indexH = indexHHiFiStart
                while indexH <= indexHHiFiCeiling {
                    let percentH = Float(indexH - indexHHiFiFloor) / Float(Self.stepsHiFi)
                    gridHiFi[indexH][0].interpX = percentH
                    gridHiFi[indexH][0].interpY = 0.0
                    indexH += 1
                }
                indexHLoFi += 1
            }
            
            var indexVLoFi = 0
            while indexVLoFi < (countVLoFi - 1) {
                let indexVHiFiFloor = indexVLoFi * Self.stepsHiFi
                let indexVHiFiStart = indexVLoFi * Self.stepsHiFi + 1
                let indexVHiFiCeiling = (indexVLoFi + 1) * Self.stepsHiFi
                
                gridLoFiFloorV[indexVLoFi] = indexVHiFiFloor
                gridLoFiStartV[indexVLoFi] = indexVHiFiStart
                gridLoFiCeilingV[indexVLoFi] = indexVHiFiCeiling
                
                indexV = indexVHiFiStart
                while indexV <= indexVHiFiCeiling {
                    let percentV = Float(indexV - indexVHiFiFloor) / Float(Self.stepsHiFi)
                    gridHiFi[0][indexV].interpX = 0.0
                    gridHiFi[0][indexV].interpY = percentV
                    indexV += 1
                }
                indexVLoFi += 1
            }
            
            indexVLoFi = 0
            while indexVLoFi < (countVLoFi - 1) {
                let indexVHiFiFloor = gridLoFiFloorV[indexVLoFi]
                let indexVHiFiStart = gridLoFiStartV[indexVLoFi]
                let indexVHiFiCeiling = gridLoFiCeilingV[indexVLoFi]
                indexHLoFi = 0
                while indexHLoFi < (countHLoFi - 1) {
                    let indexHHiFiFloor = gridLoFiFloorH[indexHLoFi]
                    let indexHHiFiStart = gridLoFiStartH[indexHLoFi]
                    let indexHHiFiCeiling = gridLoFiCeilingH[indexHLoFi]
                    indexV = indexVHiFiStart
                    while indexV <= indexVHiFiCeiling {
                        let percentV = Float(indexV - indexVHiFiFloor) / Float(Self.stepsHiFi)
                        indexH = indexHHiFiStart
                        while indexH <= indexHHiFiCeiling {
                            let percentH = Float(indexH - indexHHiFiFloor) / Float(Self.stepsHiFi)
                            gridHiFi[indexH][indexV].interpX = percentH
                            gridHiFi[indexH][indexV].interpY = percentV
                            indexH += 1
                        }
                        indexV += 1
                    }
                    indexHLoFi += 1
                }
                indexVLoFi += 1
            }
        }
    }
    
    func calculateNodePositionsHiFi() async {
        
        if countHHiFi > 0 && countVHiFi > 0 {
            var indexV = 0
            var indexH = 0
            
            gridHiFi[0][0].x = gridLoFi[0][0].x
            gridHiFi[0][0].y = gridLoFi[0][0].y
            
            var indexHLoFi = 0
            while indexHLoFi < (countHLoFi - 1) {
                
                let nodeLoFi1 = gridLoFi[indexHLoFi][0]
                let nodeLoFi2 = gridLoFi[indexHLoFi + 1][0]
                
                let indexHHiFiStart = gridLoFiStartH[indexHLoFi]
                let indexHHiFiCeiling = gridLoFiCeilingH[indexHLoFi]
                
                indexH = indexHHiFiStart
                while indexH <= indexHHiFiCeiling {
                    let x = nodeLoFi1.x + (nodeLoFi2.x - nodeLoFi1.x) * gridHiFi[indexH][0].interpX
                    let y = nodeLoFi1.y
                    gridHiFi[indexH][0].x = x
                    gridHiFi[indexH][0].y = y
                    
                    indexH += 1
                }
                
                indexHLoFi += 1
            }
            
            var indexVLoFi = 0
            while indexVLoFi < (countVLoFi - 1) {
                
                let nodeLoFi1 = gridLoFi[0][indexVLoFi]
                let nodeLoFi2 = gridLoFi[0][indexVLoFi + 1]
                
                let indexVHiFiStart = gridLoFiStartV[indexVLoFi]
                let indexVHiFiCeiling = gridLoFiCeilingV[indexVLoFi]
                
                indexV = indexVHiFiStart
                while indexV <= indexVHiFiCeiling {
                    let x = nodeLoFi1.x
                    let y = nodeLoFi1.y + (nodeLoFi2.y - nodeLoFi1.y) * gridHiFi[0][indexV].interpY
                    gridHiFi[0][indexV].x = x
                    gridHiFi[0][indexV].y = y
                    indexV += 1
                }
                
                indexVLoFi += 1
            }
            
            indexVLoFi = 0
            while indexVLoFi < (countVLoFi - 1) {
                
                let indexVHiFiStart = gridLoFiStartV[indexVLoFi]
                let indexVHiFiCeiling = gridLoFiCeilingV[indexVLoFi]
                
                indexHLoFi = 0
                while indexHLoFi < (countHLoFi - 1) {
                    
                    let indexHHiFiStart = gridLoFiStartH[indexHLoFi]
                    let indexHHiFiCeiling = gridLoFiCeilingH[indexHLoFi]
                    
                    let nodeLoFi1 = gridLoFi[indexHLoFi][indexVLoFi]
                    let nodeLoFi2 = gridLoFi[indexHLoFi + 1][indexVLoFi]
                    let nodeLoFi3 = gridLoFi[indexHLoFi][indexVLoFi + 1]
                    
                    indexV = indexVHiFiStart
                    while indexV <= indexVHiFiCeiling {
                        
                        indexH = indexHHiFiStart
                        while indexH <= indexHHiFiCeiling {
                            let x = nodeLoFi1.x + (nodeLoFi2.x - nodeLoFi1.x) * gridHiFi[indexH][indexV].interpX
                            let y = nodeLoFi1.y + (nodeLoFi3.y - nodeLoFi1.y) * gridHiFi[indexH][indexV].interpY
                            gridHiFi[indexH][indexV].x = x
                            gridHiFi[indexH][indexV].y = y
                            indexH += 1
                        }
                        indexV += 1
                    }
                    indexHLoFi += 1
                }
                indexVLoFi += 1
            }
        }
    }
    
    func calculateNodeInsideHiFi(ringBuilderWeightPointInsidePolygonBucket: RingBuilderWeightPointInsidePolygonBucket) async {
        
        var indexV = 1
        var indexH = 1
        
        while indexV < countVHiFi {
            indexH = 1
            while indexH < countHHiFi {
                let x = gridHiFi[indexH][indexV].x
                let y = gridHiFi[indexH][indexV].y
                if ringBuilderWeightPointInsidePolygonBucket.query(x: x, y: y) {
                    gridHiFi[indexH][indexV].isInside = true
                } else {
                    gridHiFi[indexH][indexV].isInside = false
                }
                indexH += 1
            }
            indexV += 1
        }
    }
    
    func calculateDistanceFromEdgeHiFi() async {
        
        var indexV = 0
        var indexH = 0
        if countHHiFi > 0 && countVHiFi > 0 {
            
            indexV = 0
            indexH = 0
            var indexHLoFi = 0
            var indexVLoFi = 0
            while indexVLoFi < (countVLoFi - 1) {
                
                //TODO
                let indexVHiFiStart = gridLoFiStartV[indexVLoFi]
                let indexVHiFiCeiling = gridLoFiCeilingV[indexVLoFi]
                
                indexHLoFi = 0
                while indexHLoFi < (countHLoFi - 1) {
                    
                    let indexHHiFiStart = gridLoFiStartH[indexHLoFi]
                    let indexHHiFiCeiling = gridLoFiCeilingH[indexHLoFi]
                    
                    let nodeLoFi1 = gridLoFi[indexHLoFi][indexVLoFi]
                    let nodeLoFi2 = gridLoFi[indexHLoFi + 1][indexVLoFi]
                    let nodeLoFi3 = gridLoFi[indexHLoFi][indexVLoFi + 1]
                    let nodeLoFi4 = gridLoFi[indexHLoFi + 1][indexVLoFi + 1]
                    
                    // Gather up the line segments from these 4...
                    removeAllTempWeightSegments()
                    
                    //unvisit all from 1
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi1.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi1.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        ringBuilderWeightSegment.isVisited = false
                    }
                    
                    //unvisit all from 2
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi2.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi2.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        ringBuilderWeightSegment.isVisited = false
                    }
                    
                    //unvisit all from 3
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi3.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi3.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        ringBuilderWeightSegment.isVisited = false
                    }
                    
                    //unvisit all from 4
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi3.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi3.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        ringBuilderWeightSegment.isVisited = false
                    }
                    
                    //visit unvisited from 1
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi1.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi1.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        if ringBuilderWeightSegment.isVisited == false {
                            addTempWeightSegment(ringBuilderWeightSegment)
                            ringBuilderWeightSegment.isVisited = true
                        }
                    }
                    
                    //visit unvisited from 2
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi2.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi2.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        if ringBuilderWeightSegment.isVisited == false {
                            addTempWeightSegment(ringBuilderWeightSegment)
                            ringBuilderWeightSegment.isVisited = true
                        }
                    }
                    
                    //visit unvisited from 3
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi3.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi3.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        if ringBuilderWeightSegment.isVisited == false {
                            addTempWeightSegment(ringBuilderWeightSegment)
                            ringBuilderWeightSegment.isVisited = true
                        }
                    }
                    
                    //visit unvisited from 4
                    for ringBuilderWeightSegmentIndex in 0..<nodeLoFi1.ringBuilderWeightSegmentCount {
                        let ringBuilderWeightSegment = nodeLoFi4.ringBuilderWeightSegments[ringBuilderWeightSegmentIndex]
                        if ringBuilderWeightSegment.isVisited == false {
                            addTempWeightSegment(ringBuilderWeightSegment)
                            ringBuilderWeightSegment.isVisited = true
                        }
                    }
                    
                    indexV = indexVHiFiStart
                    while indexV <= indexVHiFiCeiling {
                        
                        indexH = indexHHiFiStart
                        while indexH <= indexHHiFiCeiling {
                            let x = gridHiFi[indexH][indexV].x
                            let y = gridHiFi[indexH][indexV].y
                            
                            var bestDistanceSquared = Float(100_000_000.0)
                            
                            for ringBuilderWeightSegmentsIndex in 0..<tempWeightSegmentCount {
                                let ringBuilderWeightSegment = tempWeightSegments[ringBuilderWeightSegmentsIndex]
                                let distanceSquared = ringBuilderWeightSegment.distanceSquaredToClosestPoint(x, y)
                                ringBuilderWeightSegment.storedDistance = distanceSquared
                                ringBuilderWeightSegment.isVisited = false
                                if distanceSquared < bestDistanceSquared {
                                    bestDistanceSquared = distanceSquared
                                }
                            }
                            
                            if bestDistanceSquared > MathKit.Math.epsilon {
                                let distance = sqrtf(bestDistanceSquared)
                                gridHiFi[indexH][indexV].distanceFromEdge = distance
                            } else {
                                gridHiFi[indexH][indexV].distanceFromEdge = 0.0
                            }
                            
                            indexH += 1
                        }
                        indexV += 1
                    }
                    indexHLoFi += 1
                }
                indexVLoFi += 1
            }
        }
        
        maximumDistanceFromEdgeHiFi = Float(0.0)
        
        indexV = 1
        while indexV < countVHiFi {
            indexH = 1
            while indexH < countHHiFi {
                if gridHiFi[indexH][indexV].isInside {
                    if gridHiFi[indexH][indexV].distanceFromEdge > maximumDistanceFromEdgeHiFi {
                        maximumDistanceFromEdgeHiFi = gridHiFi[indexH][indexV].distanceFromEdge
                    }
                }
                indexH += 1
            }
            indexV += 1
        }
        
        if maximumDistanceFromEdgeHiFi > MathKit.Math.epsilon {
            indexV = 1
            while indexV < countVHiFi {
                indexH = 1
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        gridHiFi[indexH][indexV].distanceFromEdgePercent = gridHiFi[indexH][indexV].distanceFromEdge / maximumDistanceFromEdgeHiFi
                    }
                    indexH += 1
                }
                indexV += 1
            }
        } else {
            indexV = 1
            while indexV < countVHiFi {
                indexH = 1
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        gridHiFi[indexH][indexV].distanceFromEdgePercent = 0.0
                    }
                    indexH += 1
                }
                indexV += 1
            }
        }
    }
    
    //OfInsideNodes
    func calculateCentroidHiFi() async {
        var numberInside = 0
        var sumX = Float(0.0)
        var sumY = Float(0.0)
        
        var indexV = 0
        while indexV < countVHiFi {
            var indexH = 0
            while indexH < countHHiFi {
                
                if gridHiFi[indexH][indexV].isInside {
                    let x = gridHiFi[indexH][indexV].x
                    let y = gridHiFi[indexH][indexV].y
                    sumX += x
                    sumY += y
                    numberInside += 1
                }
                indexH += 1
            }
            indexV += 1
        }
        
        if numberInside > 0 {
            centroidXHiFi = sumX / Float(numberInside)
            centroidYHiFi = sumY / Float(numberInside)
        }
    }
    
    //OfInsideNodes
    func calculateDistanceFromCentroidHiFi() async {
        var maximumDistance = Float(0.0)
        var indexV = 0
        var indexH = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                if gridHiFi[indexH][indexV].isInside {
                    let x = gridHiFi[indexH][indexV].x
                    let y = gridHiFi[indexH][indexV].y
                    let diffX = (x - centroidXHiFi)
                    let diffY = (y - centroidYHiFi)
                    let distanceSquared = (diffX * diffX) + (diffY * diffY)
                    if distanceSquared > MathKit.Math.epsilon {
                        let distance = sqrtf(distanceSquared)
                        gridHiFi[indexH][indexV].distanceFromCentroid = distance
                        if distance > maximumDistance {
                            maximumDistance = distance
                        }
                    } else {
                        gridHiFi[indexH][indexV].distanceFromCentroid = 0.0
                    }
                }
                indexH += 1
            }
            indexV += 1
        }
        
        if maximumDistance > MathKit.Math.epsilon {
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        gridHiFi[indexH][indexV].distanceFromCentroidPercent = gridHiFi[indexH][indexV].distanceFromCentroid / maximumDistance
                    }
                    indexH += 1
                }
                indexV += 1
            }
        } else {
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        gridHiFi[indexH][indexV].distanceFromCentroidPercent = 0.0
                    }
                    indexH += 1
                }
                indexV += 1
            }
        }
    }
    
    func calculateGravityAdjustmentPercent_PartA(angle: Float, magnitude: Float) async {
        
        var indexV = 0
        var indexH = 0
        
        if magnitude <= 0.0 || (angle == 0.0) {
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        let x = gridHiFi[indexH][indexV].x
                        let y = gridHiFi[indexH][indexV].y
                        gridHiFi[indexH][indexV].checkX = x
                        gridHiFi[indexH][indexV].checkY = y
                    }
                    indexH += 1
                }
                indexV += 1
            }
        } else {
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        let x = gridHiFi[indexH][indexV].x
                        let y = gridHiFi[indexH][indexV].y
                        let diffX = (centroidXHiFi - x)
                        let diffY = (centroidYHiFi - y)
                        let distanceSquared = (diffX * diffX) + (diffY * diffY)
                        if distanceSquared > MathKit.Math.epsilon {
                            let distance = sqrtf(distanceSquared)
                            let swivel = -atan2(diffX, diffY) - angle
                            let dirX = sinf(swivel)
                            let dirY = -cosf(swivel)
                            gridHiFi[indexH][indexV].checkX = centroidXHiFi + dirX * distance
                            gridHiFi[indexH][indexV].checkY = centroidYHiFi + dirY * distance
                        } else {
                            gridHiFi[indexH][indexV].checkX = x
                            gridHiFi[indexH][indexV].checkY = y
                        }
                    }
                    indexH += 1
                }
                indexV += 1
            }
        }
    }
    
    func calculateGravityAdjustmentPercent_PartB(angle: Float, magnitude: Float) async {
        
        var indexV = 0
        var indexH = 0
        
        var magnitude = magnitude
        if magnitude < 0.0 { magnitude = 0.0 }
        if magnitude > 1.0 { magnitude = 1.0 }
        
        if magnitude <= 0.0 || (angle == 0.0) {
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    gridHiFi[indexH][indexV].gravityAdjustmentFactor = 0.0
                    indexH += 1
                }
                indexV += 1
            }
        } else {
            
            var minX = Float(100_000_000.0)
            var minY = Float(100_000_000.0)
            var maxX = Float(-100_000_000.0)
            var maxY = Float(-100_000_000.0)
            
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    if gridHiFi[indexH][indexV].isInside {
                        let x = gridHiFi[indexH][indexV].checkX
                        let y = gridHiFi[indexH][indexV].checkY
                        if x < minX { minX = x }
                        if y < minY { minY = y }
                        if x > maxX { maxX = x }
                        if y > maxY { maxY = y }
                    }
                    indexH += 1
                }
                indexV += 1
            }
            
            let rangeX = maxX - minX
            let rangeY = maxY - minY
            if rangeX > MathKit.Math.epsilon && rangeY > MathKit.Math.epsilon {
                indexV = 0
                while indexV < countVHiFi {
                    indexH = 0
                    while indexH < countHHiFi {
                        if gridHiFi[indexH][indexV].isInside {
                            let numerator = gridHiFi[indexH][indexV].checkY - minY
                            let percentInverse = (numerator / rangeY)
                            let percent = (1.0 - percentInverse)
                            
                            var factor = Float(-1.0) + Float(2.0) * percent
                            
                            factor *= magnitude
                            
                            if factor < -1.0 { factor = -1.0 }
                            if factor > 1.0 { factor = 1.0 }
                            
                            gridHiFi[indexH][indexV].gravityAdjustmentFactor = factor
                        }
                        indexH += 1
                    }
                    indexV += 1
                }
            } else {
                indexV = 0
                while indexV < countVHiFi {
                    indexH = 0
                    while indexH < countHHiFi {
                        if gridHiFi[indexH][indexV].isInside {
                            gridHiFi[indexH][indexV].gravityAdjustmentFactor = 0.0
                        }
                        indexH += 1
                    }
                    indexV += 1
                }
            }
        }
    }
    
    func calculateInclusion_PartA(ringIndex: Int, numberOfRings: Int) async {
        
        var indexV = 0
        var indexH = 0
        if numberOfRings >= 1 && (ringIndex >= 0) && (ringIndex < numberOfRings) {
            
            var thresholdPercent = Float(ringIndex + 1) / Float(numberOfRings + 1)
            if thresholdPercent < 0.0 { thresholdPercent = 0.0 }
            if thresholdPercent > 1.0 { thresholdPercent = 1.0 }
            
            indexV = 0
            indexV = 0
            while indexV < countVHiFi {
                indexH = 0
                while indexH < countHHiFi {
                    
                    var thresholdFactor = gridHiFi[indexH][indexV].distanceFromEdgePercent
                    thresholdFactor += gridHiFi[indexH][indexV].gravityAdjustmentFactor * (thresholdPercent * 0.70)
                    
                    if thresholdFactor >= thresholdPercent {
                        gridHiFi[indexH][indexV].isIncluded = true
                    }
                    
                    indexH += 1
                }
                indexV += 1
            }
        }
    }
    
    func calculateInclusionExists(ringIndex: Int, numberOfRings: Int) async -> Bool {
        
        var indexV = 0
        var indexH = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                if gridHiFi[indexH][indexV].isIncluded {
                    return true
                }
                indexH += 1
            }
            indexV += 1
        }
        return false
    }
    
    // Erode shape
    
    // 0 0 1 1 1 0 0
    // 0 1 1 1 1 1 0
    // 1 1 1 1 1 1 1
    // 1 1 1 X 1 1 1
    // 1 1 1 1 1 1 1
    // 0 1 1 1 1 1 0
    // 0 0 1 1 1 0 0
    
    func calculateInclusion_PartB(numberOfTimes: Int) async {
        if numberOfTimes <= 0 {
            return
        }
        let countH3 = countHHiFi - 3
        let countV3 = countVHiFi - 3
        var indexV = 0
        var indexH = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                if indexH > 2 && indexH < countH3 && indexV > 2 && indexV < countV3 {
                    if gridHiFi[indexH][indexV].isIncluded {
                        if 
                            gridHiFi[indexH - 1][indexV - 1].isIncluded && // ring @ 1, left up
                                gridHiFi[indexH - 1][indexV + 0].isIncluded && // ring @ 1, left
                                gridHiFi[indexH - 1][indexV + 1].isIncluded && // ring @ 1, left down
                                gridHiFi[indexH + 0][indexV - 1].isIncluded && // ring @ 1, up
                                gridHiFi[indexH + 1][indexV - 1].isIncluded && // ring @ 1, right up
                                gridHiFi[indexH + 1][indexV + 0].isIncluded && // ring @ 1, right
                                gridHiFi[indexH + 1][indexV + 1].isIncluded && // ring @ 1, right down
                                gridHiFi[indexH + 0][indexV + 1].isIncluded && // ring @ 1, down
                                
                                gridHiFi[indexH - 2][indexV - 2].isIncluded && // ring @ 2, left up up
                                gridHiFi[indexH - 2][indexV - 1].isIncluded && // ring @ 2, left up
                                gridHiFi[indexH - 2][indexV + 0].isIncluded && // ring @ 2, left
                                gridHiFi[indexH - 2][indexV + 1].isIncluded && // ring @ 2, left down
                                gridHiFi[indexH - 2][indexV + 2].isIncluded && // ring @ 2, left down down
                                
                                gridHiFi[indexH - 1][indexV - 2].isIncluded && // ring @ 2, up left
                                gridHiFi[indexH + 0][indexV - 2].isIncluded && // ring @ 2, up
                                gridHiFi[indexH + 1][indexV - 2].isIncluded && // ring @ 2, up right
                                
                                gridHiFi[indexH + 2][indexV - 2].isIncluded && // ring @ 2, right up up
                                gridHiFi[indexH + 2][indexV - 1].isIncluded && // ring @ 2, right up
                                gridHiFi[indexH + 2][indexV + 0].isIncluded && // ring @ 2, right
                                gridHiFi[indexH + 2][indexV + 1].isIncluded && // ring @ 2, right down
                                gridHiFi[indexH + 2][indexV + 2].isIncluded && // ring @ 2, right down down
                                
                                gridHiFi[indexH - 1][indexV + 2].isIncluded && // ring @ 2, down left
                                gridHiFi[indexH + 0][indexV + 2].isIncluded && // ring @ 2, down
                                gridHiFi[indexH + 1][indexV + 2].isIncluded && // ring @ 2, down right
                                
                                gridHiFi[indexH - 1][indexV - 3].isIncluded && // ring @ 3, up left
                                gridHiFi[indexH + 0][indexV - 3].isIncluded && // ring @ 3, up
                                gridHiFi[indexH + 1][indexV - 3].isIncluded && // ring @ 3, up right
                                
                                gridHiFi[indexH - 3][indexV - 1].isIncluded && // ring @ 3, left up
                                gridHiFi[indexH - 3][indexV + 0].isIncluded && // ring @ 3, left
                                gridHiFi[indexH - 3][indexV + 1].isIncluded && // ring @ 3, left down
                                
                                gridHiFi[indexH - 1][indexV + 3].isIncluded && // ring @ 3, down left
                                gridHiFi[indexH + 0][indexV + 3].isIncluded && // ring @ 3, down
                                gridHiFi[indexH + 1][indexV + 3].isIncluded && // ring @ 3, down right
                                
                                gridHiFi[indexH + 3][indexV - 1].isIncluded && // ring @ 3, right up
                                gridHiFi[indexH + 3][indexV + 0].isIncluded && // ring @ 3, right
                                gridHiFi[indexH + 3][indexV + 1].isIncluded // ring @ 3, right down
                        {
                            gridHiFi[indexH][indexV].isEroded = true
                            
                        } else {
                            gridHiFi[indexH][indexV].isEroded = false
                        }
                    } else {
                        gridHiFi[indexH][indexV].isEroded = false
                    }
                } else {
                    gridHiFi[indexH][indexV].isEroded = false
                }
                indexH += 1
            }
            indexV += 1
        }
        
        indexV = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                
                if gridHiFi[indexH][indexV].isEroded && gridHiFi[indexH][indexV].isInside {
                    gridHiFi[indexH][indexV].isIncluded = true
                } else {
                    gridHiFi[indexH][indexV].isIncluded = false
                }
                indexH += 1
            }
            indexV += 1
        }
        
        await calculateInclusion_PartB(numberOfTimes: numberOfTimes - 1)
    }
    
    // Dilate shape
    
    // 0 0 1 1 1 0 0
    // 0 1 1 1 1 1 0
    // 1 1 1 1 1 1 1
    // 1 1 1 X 1 1 1
    // 1 1 1 1 1 1 1
    // 0 1 1 1 1 1 0
    // 0 0 1 1 1 0 0
    
    func calculateInclusion_PartC(numberOfTimes: Int) async {
        if numberOfTimes <= 0 {
            return
        }
        let countH2 = countHHiFi - 2
        let countV2 = countVHiFi - 2
        var indexV = 0
        var indexH = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                gridHiFi[indexH][indexV].isDilated = false
                indexH += 1
            }
            indexV += 1
        }
        
        indexV = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                if indexH > 0 && indexH < countH2 && indexV > 0 && indexV < countV2 {
                    if gridHiFi[indexH][indexV].isIncluded {
                        
                        gridHiFi[indexH - 1][indexV - 1].isDilated = true // ring @ 1, left up
                        gridHiFi[indexH - 1][indexV + 0].isDilated = true // ring @ 1, left
                        gridHiFi[indexH - 1][indexV + 1].isDilated = true // ring @ 1, left down
                        gridHiFi[indexH + 0][indexV - 1].isDilated = true // ring @ 1, up
                        gridHiFi[indexH + 1][indexV - 1].isDilated = true // ring @ 1, right up
                        gridHiFi[indexH + 1][indexV + 0].isDilated = true // ring @ 1, right
                        gridHiFi[indexH + 1][indexV + 1].isDilated = true // ring @ 1, right down
                        gridHiFi[indexH + 0][indexV + 1].isDilated = true // ring @ 1, down
                        
                        gridHiFi[indexH - 2][indexV - 2].isDilated = true // ring @ 2, left up up
                        gridHiFi[indexH - 2][indexV - 1].isDilated = true // ring @ 2, left up
                        gridHiFi[indexH - 2][indexV + 0].isDilated = true // ring @ 2, left
                        gridHiFi[indexH - 2][indexV + 1].isDilated = true // ring @ 2, left down
                        gridHiFi[indexH - 2][indexV + 2].isDilated = true // ring @ 2, left down down
                        
                        gridHiFi[indexH - 1][indexV - 2].isDilated = true // ring @ 2, up left
                        gridHiFi[indexH + 0][indexV - 2].isDilated = true // ring @ 2, up
                        gridHiFi[indexH + 1][indexV - 2].isDilated = true // ring @ 2, up right
                        
                        gridHiFi[indexH + 2][indexV - 2].isDilated = true // ring @ 2, right up up
                        gridHiFi[indexH + 2][indexV - 1].isDilated = true // ring @ 2, right up
                        gridHiFi[indexH + 2][indexV + 0].isDilated = true // ring @ 2, right
                        gridHiFi[indexH + 2][indexV + 1].isDilated = true // ring @ 2, right down
                        gridHiFi[indexH + 2][indexV + 2].isDilated = true // ring @ 2, right down down
                        
                        gridHiFi[indexH - 1][indexV + 2].isDilated = true // ring @ 2, down left
                        gridHiFi[indexH + 0][indexV + 2].isDilated = true // ring @ 2, down
                        gridHiFi[indexH + 1][indexV + 2].isDilated = true // ring @ 2, down right
                        
                        gridHiFi[indexH - 1][indexV - 3].isDilated = true // ring @ 3, up left
                        gridHiFi[indexH + 0][indexV - 3].isDilated = true // ring @ 3, up
                        gridHiFi[indexH + 1][indexV - 3].isDilated = true // ring @ 3, up right
                        
                        gridHiFi[indexH - 3][indexV - 1].isDilated = true // ring @ 3, left up
                        gridHiFi[indexH - 3][indexV + 0].isDilated = true // ring @ 3, left
                        gridHiFi[indexH - 3][indexV + 1].isDilated = true // ring @ 3, left down
                        
                        gridHiFi[indexH - 1][indexV + 3].isDilated = true // ring @ 3, down left
                        gridHiFi[indexH + 0][indexV + 3].isDilated = true // ring @ 3, down
                        gridHiFi[indexH + 1][indexV + 3].isDilated = true // ring @ 3, down right
                        
                        gridHiFi[indexH + 3][indexV - 1].isDilated = true // ring @ 3, right up
                        gridHiFi[indexH + 3][indexV + 0].isDilated = true // ring @ 3, right
                        gridHiFi[indexH + 3][indexV + 1].isDilated = true // ring @ 3, right down
                    }
                }
                indexH += 1
            }
            indexV += 1
        }
        
        indexV = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                if gridHiFi[indexH][indexV].isDilated && gridHiFi[indexH][indexV].isInside {
                    gridHiFi[indexH][indexV].isIncluded = true
                } else {
                    gridHiFi[indexH][indexV].isIncluded = false
                }
                indexH += 1
            }
            indexV += 1
        }
        
        await calculateInclusion_PartC(numberOfTimes: numberOfTimes - 1)
    }
    
    func stackPush(x: Int, y: Int) {
        while stackX.count <= stackCount {
            stackX.append(x)
        }
        while stackY.count <= stackCount {
            stackY.append(y)
        }
        stackX[stackCount] = x
        stackY[stackCount] = y
        stackCount += 1
    }
    
    func calculateInclusion_PartD() async {
        stackCount = 0
        var indexV = 0
        var indexH = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                gridHiFi[indexH][indexV].isVisited = false
                gridHiFi[indexH][indexV].groupIndex = -1
                indexH += 1
            }
            indexV += 1
        }
        
        groupIndex = 1
        indexV = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                if (gridHiFi[indexH][indexV].isIncluded == true) && (gridHiFi[indexH][indexV].isVisited == false) {
                    gridHiFi[indexH][indexV].isVisited = true
                    stackPush(x: indexH, y: indexV)
                    await calculateInclusion_PartD_Helper()
                    groupIndex += 1
                }
                indexH += 1
            }
            indexV += 1
        }
    }
    
    private func calculateInclusion_PartD_Helper() async {
        
        let countH1 = countHHiFi - 1
        let countV1 = countVHiFi - 1
        
        while stackCount > 0 {
            
            stackCount -= 1
            let popX = stackX[stackCount]
            let popY = stackY[stackCount]
            
            gridHiFi[popX][popY].groupIndex = groupIndex
            
            if popX > 0 {
                let testX = popX - 1
                let testY = popY
                if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                    gridHiFi[testX][testY].isVisited = true
                    stackPush(x: testX, y: testY)
                }
            }
            if popX < countH1 {
                let testX = popX + 1
                let testY = popY
                if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                    gridHiFi[testX][testY].isVisited = true
                    stackPush(x: testX, y: testY)
                }
            }
            if popY > 0 {
                let testX = popX
                let testY = popY - 1
                if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                    gridHiFi[testX][testY].isVisited = true
                    stackPush(x: testX, y: testY)
                }
            }
            if popY < countV1 {
                let testX = popX
                let testY = popY + 1
                if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                    gridHiFi[testX][testY].isVisited = true
                    stackPush(x: testX, y: testY)
                }
            }
        }
    }
    
    func calculateInclusion_PartE() async {
        var groupCounts = [Int](repeating: 0, count: 32)
        var maxGroupIndex = 0
        var indexV = 0
        var indexH = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                let groupIndex = gridHiFi[indexH][indexV].groupIndex
                if groupIndex > 0 && groupIndex < 32 {
                    groupCounts[groupIndex] += 1
                    if gridHiFi[indexH][indexV].groupIndex > maxGroupIndex {
                        maxGroupIndex = gridHiFi[indexH][indexV].groupIndex
                    }
                }
                indexH += 1
            }
            indexV += 1
        }
        
        var largestIndex = -1
        var largestCount = 0
        
        for index in 0..<32 {
            if groupCounts[index] > largestCount {
                largestCount = groupCounts[index]
                largestIndex = index
            }
        }
        
        indexV = 0
        while indexV < countVHiFi {
            indexH = 0
            while indexH < countHHiFi {
                let groupIndex = gridHiFi[indexH][indexV].groupIndex
                if groupIndex == largestIndex {
                    gridHiFi[indexH][indexV].isIncluded = true
                } else {
                    gridHiFi[indexH][indexV].isIncluded = false
                }
                indexH += 1
            }
            indexV += 1
        }
    }
    
    func calculateEdgePoints() async {
        var indexV = 0
        while indexV < countVHiFi {
            var indexH = 0
            while indexH < countHHiFi {
                gridHiFi[indexH][indexV].isVisited = false
                indexH += 1
            }
            indexV += 1
        }
        
        let countH1 = countHHiFi - 1
        let countV1 = countVHiFi - 1
        
        var firstEdgePointIndexX = -1
        var firstEdgePointIndexY = -1
        
        let side = Int.random(in: 0...3)
        
        if side == 0 {
            indexV = 0
            while indexV < countVHiFi && firstEdgePointIndexX == -1 {
                var indexH = 0
                while indexH < countHHiFi && firstEdgePointIndexY == -1 {
                    if gridHiFi[indexH][indexV].isIncluded {
                        
                        if isEdgePoint(x: indexH, y: indexV) {
                            firstEdgePointIndexX = indexH
                            firstEdgePointIndexY = indexV
                        }
                    }
                    indexH += 1
                }
                indexV += 1
            }
        } else if side == 1 {
            indexV = countVHiFi - 1
            while indexV >= 0 && firstEdgePointIndexX == -1 {
                var indexH = 0
                while indexH < countHHiFi && firstEdgePointIndexY == -1 {
                    if gridHiFi[indexH][indexV].isIncluded {
                        if isEdgePoint(x: indexH, y: indexV) {
                            firstEdgePointIndexX = indexH
                            firstEdgePointIndexY = indexV
                        }
                    }
                    indexH += 1
                }
                indexV -= 1
            }
        } else if side == 2 {
            var indexH = 0
            while indexH < countHHiFi && firstEdgePointIndexY == -1 {
                var indexV = 0
                while indexV < countVHiFi && firstEdgePointIndexX == -1 {
                    if gridHiFi[indexH][indexV].isIncluded {
                        if isEdgePoint(x: indexH, y: indexV) {
                            firstEdgePointIndexX = indexH
                            firstEdgePointIndexY = indexV
                        }
                    }
                    indexV += 1
                }
                indexH += 1
            }
        } else {
            var indexH = countHHiFi - 1
            while indexH >= 0 && firstEdgePointIndexY == -1 {
                var indexV = 0
                while indexV < countVHiFi && firstEdgePointIndexX == -1 {
                    if gridHiFi[indexH][indexV].isIncluded {
                        if isEdgePoint(x: indexH, y: indexV) {
                            firstEdgePointIndexX = indexH
                            firstEdgePointIndexY = indexV
                        }
                    }
                    indexV += 1
                }
                indexH -= 1
            }
        }
        
        if firstEdgePointIndexX == -1 || firstEdgePointIndexY == -1 {
            return
        }
        
        gridHiFi[firstEdgePointIndexX][firstEdgePointIndexY].isVisited = true
        edgePointList.add(firstEdgePointIndexX, firstEdgePointIndexY)
        
        var gridX = firstEdgePointIndexX
        var gridY = firstEdgePointIndexY
        
        while true {
            if gridY > 0 {
                let testY = gridY - 1
                if (gridHiFi[gridX][testY].isIncluded == true) && (gridHiFi[gridX][testY].isVisited == false) {
                    if isEdgePoint(x: gridX, y: testY) {
                        gridHiFi[gridX][testY].isVisited = true
                        edgePointList.add(gridX, testY)
                        gridY = testY
                        continue
                    }
                }
            }
            if gridY < countV1 {
                let testY = gridY + 1
                if (gridHiFi[gridX][testY].isIncluded == true) && (gridHiFi[gridX][testY].isVisited == false) {
                    if isEdgePoint(x: gridX, y: testY) {
                        gridHiFi[gridX][testY].isVisited = true
                        edgePointList.add(gridX, testY)
                        gridY = testY
                        continue
                    }
                }
            }
            
            if gridX > 0 {
                let testX = gridX - 1
                if (gridHiFi[testX][gridY].isIncluded == true) && (gridHiFi[testX][gridY].isVisited == false) {
                    if isEdgePoint(x: testX, y: gridY) {
                        gridHiFi[testX][gridY].isVisited = true
                        edgePointList.add(testX, gridY)
                        gridX = testX
                        continue
                    }
                }
            }
            
            if gridX < countH1 {
                let testX = gridX + 1
                if (gridHiFi[testX][gridY].isIncluded == true) && (gridHiFi[testX][gridY].isVisited == false) {
                    if isEdgePoint(x: testX, y: gridY) {
                        gridHiFi[testX][gridY].isVisited = true
                        edgePointList.add(testX, gridY)
                        gridX = testX
                        continue
                    }
                }
            }
            
            if gridX > 0 {
                if gridY > 0 {
                    let testX = gridX - 1
                    let testY = gridY - 1
                    if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                        if isEdgePoint(x: testX, y: testY) {
                            gridHiFi[testX][testY].isVisited = true
                            edgePointList.add(testX, testY)
                            gridX = testX
                            gridY = testY
                            continue
                        }
                    }
                }
                if gridY < countV1 {
                    let testX = gridX - 1
                    let testY = gridY + 1
                    if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                        if isEdgePoint(x: testX, y: testY) {
                            gridHiFi[testX][testY].isVisited = true
                            edgePointList.add(testX, testY)
                            gridX = testX
                            gridY = testY
                            continue
                        }
                    }
                }
            }
            
            if gridX < countH1 {
                if gridY > 0 {
                    let testX = gridX + 1
                    let testY = gridY - 1
                    if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                        if isEdgePoint(x: testX, y: testY) {
                            gridHiFi[testX][testY].isVisited = true
                            edgePointList.add(testX, testY)
                            gridX = testX
                            gridY = testY
                            continue
                        }
                    }
                }
                if gridY < countV1 {
                    let testX = gridX + 1
                    let testY = gridY + 1
                    if (gridHiFi[testX][testY].isIncluded == true) && (gridHiFi[testX][testY].isVisited == false) {
                        if isEdgePoint(x: testX, y: testY) {
                            gridHiFi[testX][testY].isVisited = true
                            edgePointList.add(testX, testY)
                            gridX = testX
                            gridY = testY
                            continue
                        }
                    }
                }
            }
            break
        }
    }
    
    func isEdgePoint(x: Int, y: Int) -> Bool {
        if x == 0 {
            return true
        }
        if x == (countHHiFi - 1) {
            return true
        }
        if y == 0 {
            return true
        }
        if y == (countVHiFi - 1) {
            return true
        }
        
        if gridHiFi[x - 1][y].isIncluded == false {
            return true
        } else if gridHiFi[x + 1][y].isIncluded == false {
            return true
        } else if gridHiFi[x][y + 1].isIncluded == false {
            return true
        } else if gridHiFi[x][y - 1].isIncluded == false {
            return true
        } else {
            return false
        }
    }
}
