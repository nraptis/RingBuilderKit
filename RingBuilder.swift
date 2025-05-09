//
//  RingBuilder.swift
//  Manifold
//
//  Created by Nick Raptis on 8/3/24.
//

import Foundation
import MathKit
import SplineReducerKit

public class RingBuilder {
    
    public static let minimumPoints = 4
    public static let maximumNumberOfRings = 5
    public static let minimumNumberOfRings = 1
    
    static let requiredEdgePoints = 32
    
    static let stepSize = Float(12.0)
    static let stepSizeSquared = (stepSize * stepSize)
    
    static let erodeCount = 3
    static let dilateCount = 3
    
    typealias Point = Math.Point
    typealias Vector = Math.Vector
    
    var splines = [ManualSpline]()
    
    let smoothingPath = OutlinePath()

    var _registerDistance = Float(2.0)
    var _registerDistanceSquared = Float(2.0)
    
    var _computeStepSize = Float(12.0)

    var _smoothingStepSize = Float(4.0)

    // The x and y as they are added in, with no modifications. (step i)
    private(set) var baseCount = 0
    private(set) var _baseCapacity = 0
    private(set) var _baseX = [Float]()
    private(set) var _baseY = [Float]()
    
    // The x and y as they are added in, with no modifications. (step e)
    private(set) var smoothCount = 0
    private(set) var _smoothCapacity = 0
    private(set) var _smoothX = [Float]()
    private(set) var _smoothY = [Float]()

    // The x and y as they are added in, with no modifications. (step i)
    private(set) var tempCount = 0
    private(set) var _tempCapacity = 0
    private(set) var _tempX = [Float]()
    private(set) var _tempY = [Float]()
    
    let ringBuilderWeightSegmentBucket = RingBuilderWeightSegmentBucket()
    let ringBuilderWeightPointInsidePolygonBucket = RingBuilderWeightPointInsidePolygonBucket()
    
    var ringBuilderWeightSegments = [RingBuilderWeightSegment]()
    var ringBuilderWeightSegmentCount = 0
    func addRingBuilderWeightSegment(_ ringBuilderWeightSegment: RingBuilderWeightSegment) {
        while ringBuilderWeightSegments.count <= ringBuilderWeightSegmentCount {
            ringBuilderWeightSegments.append(ringBuilderWeightSegment)
        }
        ringBuilderWeightSegments[ringBuilderWeightSegmentCount] = ringBuilderWeightSegment
        ringBuilderWeightSegmentCount += 1
    }
    
    func purgeRingBuilderWeightSegments() {
        for ringBuilderWeightSegmentsIndex in 0..<ringBuilderWeightSegmentCount {
            RingBuilderPartsFactory.shared.depositRingBuilderWeightSegment(ringBuilderWeightSegments[ringBuilderWeightSegmentsIndex])
        }
        ringBuilderWeightSegmentCount = 0
    }
    
    var ringBuilderWeightPoints = [RingBuilderWeightPoint]()
    var ringBuilderWeightPointCount = 0
    func addRingBuilderWeightPoint(_ ringBuilderWeightPoint: RingBuilderWeightPoint) {
        while ringBuilderWeightPoints.count <= ringBuilderWeightPointCount {
            ringBuilderWeightPoints.append(ringBuilderWeightPoint)
        }
        ringBuilderWeightPoints[ringBuilderWeightPointCount] = ringBuilderWeightPoint
        ringBuilderWeightPointCount += 1
    }
    
    func purgeRingBuilderWeightPoints() {
        for ringBuilderWeightPointIndex in 0..<ringBuilderWeightPointCount {
            RingBuilderPartsFactory.shared.depositRingBuilderWeightPoint(ringBuilderWeightPoints[ringBuilderWeightPointIndex])
        }
        ringBuilderWeightPointCount = 0
    }
    
    var angle = Float(0.0)
    var magnitude = Float(0.0)
    var numberOfRings = 3
    
    var _minX = Float(0.0)
    var _minY = Float(0.0)
    var _maxX = Float(0.0)
    var _maxY = Float(0.0)
    
    var _centerX = Float(0.0)
    var _centerY = Float(0.0)
    
    var isComputing = false
    var isErrorPresent = false
    
    var outlinePath = OutlinePath()
    
    var worldScale = Float(1.0)
    
    public init() {
        
    }
    
    public func compute_PartA(borderTool: BorderTool,
                       angle: Float,
                       jiggleRotation: Float,
                       worldScale: Float,
                       registerDistanceBase: Float,
                       computeStepBaseSize: Float,
                       smoothingStepBaseSize: Float) {
        
        isComputing = true
        isErrorPresent = false
        
        self.worldScale = worldScale
        
        computeResult.numberOfRingsRequested = 0
        
        _registerDistance = registerDistanceBase * worldScale
        _registerDistanceSquared = _registerDistance * _registerDistance
        
        _computeStepSize = computeStepBaseSize * worldScale
                
        _smoothingStepSize = smoothingStepBaseSize * worldScale
        
        self.angle = angle - jiggleRotation
        
        splines.removeAll()
        
        // Ingest from the Jiggle, the pointz.
        purgeRingBuilderWeightPoints()
        
        if borderTool.borderCount >= Self.minimumPoints {
            
            var borderIndex = 0
            while borderIndex < borderTool.borderCount {
                let ringBuilderWeightPoint = RingBuilderPartsFactory.shared.withdrawRingBuilderWeightPoint()
                ringBuilderWeightPoint.x = borderTool.borderX[borderIndex]
                ringBuilderWeightPoint.y = borderTool.borderY[borderIndex]
                addRingBuilderWeightPoint(ringBuilderWeightPoint)
                borderIndex += 1
            }
            
        } else {
            isErrorPresent = true
        }
    }
    
    //var stashedGridz = [RingBuilderGrid]()
    
    var computeResult = ComputeResult()
    
    public struct ComputeResult {
        public var numberOfRingsRequested = 0
        public var createGuidesFromSplinesResult = AttemptCreateGuidesFromSplinesResult.failure
    }
    
    public func compute_PartB(magnitude: Float,
                              numberOfRings: Int,
                              deviceFactor: Float,
                              splineReducer: SplineReducerKit.StochasticSplineReducer,
                              splineThresholdDistance: Float) async {
        
        computeResult.numberOfRingsRequested = numberOfRings
        //computeResult.numberOfRingsGenerated = 0
        
        
        var numberOfRings = numberOfRings
        if numberOfRings > RingBuilder.maximumNumberOfRings { numberOfRings = RingBuilder.maximumNumberOfRings }
        if numberOfRings < RingBuilder.minimumNumberOfRings { numberOfRings = RingBuilder.minimumNumberOfRings }
        self.numberOfRings = numberOfRings
        
        var magnitude = magnitude
        if magnitude < 0.0 { magnitude = 0.0 }
        if magnitude > 1.0 { magnitude = 1.0 }
        self.magnitude = magnitude
        
        var ringIndex = 0
        while ringIndex < numberOfRings {
            
            // So if it's not loop #0, we use the last ring computed as the seed...
            
            if ringIndex > 0 {
                
                await _intakeLastSpline(splineThresholdDistance: splineThresholdDistance)
                
            }
            
            let ringBuilderGrid = RingBuilderGrid()
            
            await _computeBuildLineSegments()
            await _computeBuildPointInsidePolygonBucket()
            await _computeSegmentBucket()
            await _computeMinMaxCenter()
            
            let minX = _minX
            let minY = _minY
            let maxX = _maxX
            let maxY = _maxY
            
            await ringBuilderGrid.sizeGridAndCalculateNodePositionsLoFi(minX: minX, minY: minY,
                                                                        maxX: maxX, maxY: maxY)
            //await ringBuilderGrid.calculateNodeInsideLoFi(ringBuilderWeightPointInsidePolygonBucket: ringBuilderWeightPointInsidePolygonBucket)
            await ringBuilderGrid.calculateDistanceFromEdgeAndNearSegmentsLoFi(ringBuilderWeightSegments: ringBuilderWeightSegments,
                                                                               ringBuilderWeightSegmentCount: ringBuilderWeightSegmentCount)
            await ringBuilderGrid.sizeGridHiFi()
            await ringBuilderGrid.calculateNodeInterpolationHiFi()
            await ringBuilderGrid.calculateNodePositionsHiFi()
            await ringBuilderGrid.calculateNodeInsideHiFi(ringBuilderWeightPointInsidePolygonBucket: ringBuilderWeightPointInsidePolygonBucket)
            await ringBuilderGrid.calculateDistanceFromEdgeHiFi()
            await ringBuilderGrid.calculateCentroidHiFi()
            await ringBuilderGrid.calculateDistanceFromCentroidHiFi()
            await ringBuilderGrid.calculateGravityAdjustmentPercent_PartA(angle: angle, magnitude: magnitude)
            await ringBuilderGrid.calculateGravityAdjustmentPercent_PartB(angle: angle, magnitude: magnitude)
            
            await ringBuilderGrid.calculateInclusion_PartA(ringIndex: ringIndex, numberOfRings: numberOfRings)
            if await ringBuilderGrid.calculateInclusionExists(ringIndex: ringIndex, numberOfRings: numberOfRings) == false {
                return
            }
            
            await ringBuilderGrid.calculateInclusion_PartB(numberOfTimes: Self.erodeCount)
            if await ringBuilderGrid.calculateInclusionExists(ringIndex: ringIndex, numberOfRings: numberOfRings) == false {
                return
            }
            
            await ringBuilderGrid.calculateInclusion_PartC(numberOfTimes: Self.dilateCount)
            if await ringBuilderGrid.calculateInclusionExists(ringIndex: ringIndex, numberOfRings: numberOfRings) == false {
                return
            }
            
            await ringBuilderGrid.calculateInclusion_PartD()
            await ringBuilderGrid.calculateInclusion_PartE()
            if await ringBuilderGrid.calculateInclusionExists(ringIndex: ringIndex, numberOfRings: numberOfRings) == false {
                return
            }
            
            await ringBuilderGrid.calculateEdgePoints()
            
            let edgePointList = ringBuilderGrid.edgePointList
            
            if !deriveBasePointsFromRingBuilder(edgePointList: edgePointList, ringBuilderGrid: ringBuilderGrid) {
                return
            }
            
            if !smooth() {
                return
            }
            
            outlinePath.removeAll(keepingCapacity: true)
            for index in 0..<smoothCount {
                outlinePath.addPoint(x: _smoothX[index],
                                     y: _smoothY[index])
            }
            outlinePath.solve(step: _computeStepSize,
                              skipFirstPoint: false,
                              skipLastPoint: false)
            
            if outlinePath.count <= 2 {
                return
            }

            let spline = await getReducedSpline(deviceFactor: deviceFactor,
                                                splineReducer: splineReducer)
            
            splines.append(spline)
            
            ringIndex += 1
        }
    }
    
    public typealias CreateGuidesHandle = ([ManualSpline],
                     Bool,
                     Bool) -> RingBuilderKit.AttemptCreateGuidesFromSplinesResult
    
    @MainActor public func compute_PartC(createGuidesHandle: CreateGuidesHandle) -> ComputeResult {
        let createGuidesFromSplinesResult = createGuidesHandle(splines, false, true)
        computeResult.createGuidesFromSplinesResult = createGuidesFromSplinesResult
        isComputing = false
        return computeResult
    }
    
    private func _intakeLastSpline(splineThresholdDistance: Float) async {
        
        if splines.count > 0 {
            
            let lastSpline = splines[splines.count - 1]
            
            outlinePath.removeAll(keepingCapacity: true)
            
            var position = Float(0.0)
            while position < lastSpline.maxPos {
                let pointX = lastSpline.getX(position)
                let pointY = lastSpline.getY(position)
                outlinePath.addPoint(x: pointX, y: pointY)
                position += 0.01
            }
            
            outlinePath.solve(step: splineThresholdDistance,
                              skipFirstPoint: false,
                              skipLastPoint: false)
            
            purgeRingBuilderWeightPoints()
            
            var outlinePathIndex = 0
            while outlinePathIndex < outlinePath.count {
                let ringBuilderWeightPoint = RingBuilderPartsFactory.shared.withdrawRingBuilderWeightPoint()
                ringBuilderWeightPoint.x = outlinePath.x[outlinePathIndex]
                ringBuilderWeightPoint.y = outlinePath.y[outlinePathIndex]
                addRingBuilderWeightPoint(ringBuilderWeightPoint)
                outlinePathIndex += 1
            }
        }
    }
    
    private func _computeBuildLineSegments() async {
        
        purgeRingBuilderWeightSegments()
        var ringBuilderWeightPointIndex1 = 0
        var ringBuilderWeightPointIndex2 = 1
        while ringBuilderWeightPointIndex1 < ringBuilderWeightPointCount {
            let ringBuilderWeightPoint1 = ringBuilderWeightPoints[ringBuilderWeightPointIndex1]
            let ringBuilderWeightPoint2 = ringBuilderWeightPoints[ringBuilderWeightPointIndex2]
            let ringBuilderWeightSegment = RingBuilderPartsFactory.shared.withdrawRingBuilderWeightSegment()
            ringBuilderWeightSegment.x1 = ringBuilderWeightPoint1.x
            ringBuilderWeightSegment.y1 = ringBuilderWeightPoint1.y
            ringBuilderWeightSegment.x2 = ringBuilderWeightPoint2.x
            ringBuilderWeightSegment.y2 = ringBuilderWeightPoint2.y
            ringBuilderWeightSegment.precompute()
            
            addRingBuilderWeightSegment(ringBuilderWeightSegment)
            if ringBuilderWeightSegment.isIllegal {
                isErrorPresent = true
                return
            }
            
            ringBuilderWeightPointIndex1 += 1
            ringBuilderWeightPointIndex2 += 1
            if ringBuilderWeightPointIndex2 == ringBuilderWeightPointCount {
                ringBuilderWeightPointIndex2 = 0
            }
        }
    }
    
    private func _computeBuildPointInsidePolygonBucket() async {
        ringBuilderWeightPointInsidePolygonBucket.build(ringBuilderWeightSegments: ringBuilderWeightSegments,
                                                   ringBuilderWeightSegmentCount: ringBuilderWeightSegmentCount)
    }
    
    private func _computeSegmentBucket() async {
        ringBuilderWeightSegmentBucket.build(ringBuilderWeightSegments: ringBuilderWeightSegments,
                                        ringBuilderWeightSegmentCount: ringBuilderWeightSegmentCount)
    }
    
    private func _computeMinMaxCenter() async {
        if ringBuilderWeightPoints.count > 0 {
            _minX = ringBuilderWeightPoints[0].x
            _minY = ringBuilderWeightPoints[0].y
            _maxX = ringBuilderWeightPoints[0].x
            _maxY = ringBuilderWeightPoints[0].y
            
            for ringBuilderWeightPointIndex in 0..<ringBuilderWeightPointCount {
                let ringBuilderWeightPoint = ringBuilderWeightPoints[ringBuilderWeightPointIndex]
                if ringBuilderWeightPoint.x < _minX { _minX = ringBuilderWeightPoint.x }
                if ringBuilderWeightPoint.y < _minY { _minY = ringBuilderWeightPoint.y }
                
                if ringBuilderWeightPoint.x > _maxX { _maxX = ringBuilderWeightPoint.x }
                if ringBuilderWeightPoint.y > _maxY { _maxY = ringBuilderWeightPoint.y }
            }
            
            _centerX = (_minX + _maxX) * 0.5
            _centerY = (_minY + _maxY) * 0.5
        }
    }
    
    private func getReducedSpline(deviceFactor: Float,
                                  splineReducer: SplineReducerKit.StochasticSplineReducer) async -> ManualSpline {
        let inputSpline = ManualSpline()
        inputSpline.removeAll(keepingCapacity: true)
        let outlinePathCount1 = (outlinePath.count - 1)
        for outlineIndex in 0..<outlinePathCount1 {
            let x = outlinePath.x[outlineIndex]
            let y = outlinePath.y[outlineIndex]
            inputSpline.addControlPoint(x, y)
        }
        
        inputSpline.solve(closed: true)
        let outputSpline = ManualSpline()
        
        let commandScale = deviceFactor * worldScale
        
        var programmableCommands = [SplineReducerKit.StochasticSplineReducerCommand]()
        programmableCommands.append(.chopper(.init(tolerance: 3.5 * commandScale,
                                                   minimumStep: 4,
                                                   maximumStep: 6,
                                                   tryCount: 2048,
                                                   dupeOrInvalidRetryCount: 16)))
        programmableCommands.append(.chopper(.init(tolerance: 4.0 * commandScale,
                                                   minimumStep: 3,
                                                   maximumStep: 6,
                                                   tryCount: 2048,
                                                   dupeOrInvalidRetryCount: 20)))
        programmableCommands.append(.chopper(.init(tolerance: 7.0 * commandScale,
                                                   minimumStep: 2,
                                                   maximumStep: 6,
                                                   tryCount: 2048,
                                                   dupeOrInvalidRetryCount: 24)))
        programmableCommands.append(.reduceFrontAndBack(.init(tolerance: 2.0 * commandScale,
                                                              tryCount: 192,
                                                              maxCombinedPouches: 8)))
        programmableCommands.append(.reduceBackOnly(.init(tolerance: 2.0 * commandScale,
                                                          tryCount: 192,
                                                          maxCombinedPouches: 8)))
        splineReducer.reduce(inputSpline: inputSpline,
                             outputSpline: outputSpline,
                             numberOfPointsSampledForEachControlPoint: 4,
                             programmableCommands: programmableCommands)
        
        return outputSpline
    }
    
    func deriveBasePointsFromRingBuilder(edgePointList: IntPointList, ringBuilderGrid: RingBuilderGrid) -> Bool {
        
        if ringBuilderGrid.edgePointList.count < 8 {
            return false
        }
        
        baseCount = 0
        
        var edgePointIndex = 0
        
        var indexX = ringBuilderGrid.edgePointList.x[0]
        var indexY = ringBuilderGrid.edgePointList.y[0]
        
        var node = ringBuilderGrid.gridHiFi[indexX][indexY]
        
        var previousX = node.x
        var previousY = node.y
        
        addPointBase(x: previousX, y: previousY)
        
        indexX = ringBuilderGrid.edgePointList.x[ringBuilderGrid.edgePointList.count - 1]
        indexY = ringBuilderGrid.edgePointList.y[ringBuilderGrid.edgePointList.count - 1]
        
        node = ringBuilderGrid.gridHiFi[indexX][indexY]
        
        let lastX = node.x
        let lastY = node.y
        
        let checkLastCeiling = ringBuilderGrid.edgePointList.count - 14
        while edgePointIndex < ringBuilderGrid.edgePointList.count {
            let indexX = ringBuilderGrid.edgePointList.x[edgePointIndex]
            let indexY = ringBuilderGrid.edgePointList.y[edgePointIndex]
            let node = ringBuilderGrid.gridHiFi[indexX][indexY]
            let x = node.x
            let y = node.y
            
            let diffX1 = x - previousX
            let diffY1 = y - previousY
            let distanceSquared1 = diffX1 * diffX1 + diffY1 * diffY1
            
            if distanceSquared1 > Self.stepSizeSquared {
                
                if edgePointIndex > checkLastCeiling {
                    
                    let diffX2 = x - lastX
                    let diffY2 = y - lastY
                    let distanceSquared2 = diffX2 * diffX2 + diffY2 * diffY2
                    
                    if distanceSquared2 < _registerDistanceSquared {
                        break
                    }
                }
                
                addPointBase(x: previousX, y: previousY)
                
                previousX = x
                previousY = y
            }
            
            edgePointIndex += 1
        }
        
        return true
    }
    
    func smooth() -> Bool {
        tempCount = 0
        smoothCount = 0
        
        smoothingPath.removeAll(keepingCapacity: true)
        for index in 0..<baseCount {
            smoothingPath.addPoint(x: _baseX[index], y: _baseY[index])
        }
        
        // Connect back to the head.
        smoothingPath.addPoint(x: _baseX[0], y: _baseY[0])
        
        // Skip the last point...
        smoothingPath.solve(step: _smoothingStepSize,
                        skipFirstPoint: false,
                        skipLastPoint: true)
        if smoothingPath.count < 8 {
            return false
        }
        
        // Now the points are all roughly the same distance.
        for smoothingIndex in 0..<smoothingPath.count {
            let x = smoothingPath.x[smoothingIndex]
            let y = smoothingPath.y[smoothingIndex]
            addPointTemp(x: x,
                         y: y)
        }
        
        // We take a weighted average to
        // smooth out some lumps and bumps.
        
        for index in 0..<tempCount {
            
            var forward1 = index + 1
            if forward1 == tempCount {
                forward1 = 0
            }
            var forward2 = forward1 + 1
            if forward2 == tempCount {
                forward2 = 0
            }
            
            var back1 = index - 1
            if back1 < 0 { back1 = tempCount - 1 }
            
            var back2 = back1 - 1
            if back2 < 0 { back2 = tempCount - 1 }
            
            let weightedX =
            _tempX[back2] * 0.1 +
            _tempX[back1] * 0.15 +
            _tempX[index] * 0.5 +
            _tempX[forward1] * 0.15 +
            _tempX[forward2] * 0.1
            
            let weightedY =
            _tempY[back2] * 0.1 +
            _tempY[back1] * 0.15 +
            _tempY[index] * 0.5 +
            _tempY[forward1] * 0.15 +
            _tempY[forward2] * 0.1
            
            addPointSmooth(x: weightedX,
                           y: weightedY)
        }
        
        return true
    }
    
    
    func addPointBase(x: Float, y: Float) {
        if baseCount >= _baseCapacity {
            reserveCapacityBase(minimumCapacity: baseCount + (baseCount >> 1) + 1)
        }
        _baseX[baseCount] = x
        _baseY[baseCount] = y
        baseCount += 1
    }

    private func reserveCapacityBase(minimumCapacity: Int) {
        if minimumCapacity > _baseCapacity {
            _baseX.reserveCapacity(minimumCapacity)
            _baseY.reserveCapacity(minimumCapacity)
            while _baseX.count < minimumCapacity {
                _baseX.append(0.0)
            }
            while _baseY.count < minimumCapacity {
                _baseY.append(0.0)
            }
            _baseCapacity = minimumCapacity
        }
    }
    
    func addPointSmooth(x: Float, y: Float) {
        if smoothCount >= _smoothCapacity {
            reserveCapacitySmooth(minimumCapacity: smoothCount + (smoothCount >> 1) + 1)
        }
        _smoothX[smoothCount] = x
        _smoothY[smoothCount] = y
        smoothCount += 1
    }

    private func reserveCapacitySmooth(minimumCapacity: Int) {
        if minimumCapacity > _smoothCapacity {
            _smoothX.reserveCapacity(minimumCapacity)
            _smoothY.reserveCapacity(minimumCapacity)
            while _smoothX.count < minimumCapacity {
                _smoothX.append(0.0)
            }
            while _smoothY.count < minimumCapacity {
                _smoothY.append(0.0)
            }
            _smoothCapacity = minimumCapacity
        }
    }

    func addPointTemp(x: Float, y: Float) {
        if tempCount >= _tempCapacity {
            reserveCapacityTemp(minimumCapacity: tempCount + (tempCount >> 1) + 1)
        }
        _tempX[tempCount] = x
        _tempY[tempCount] = y
        tempCount += 1
    }

    private func reserveCapacityTemp(minimumCapacity: Int) {
        if minimumCapacity > _tempCapacity {
            _tempX.reserveCapacity(minimumCapacity)
            _tempY.reserveCapacity(minimumCapacity)
            while _tempX.count < minimumCapacity {
                _tempX.append(0.0)
            }
            while _tempY.count < minimumCapacity {
                _tempY.append(0.0)
            }
            _tempCapacity = minimumCapacity
        }
    }
    
}
