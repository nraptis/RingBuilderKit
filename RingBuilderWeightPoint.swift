//
//  RingBuilderWeightPoint.swift
//  RingBuilderKit
//
//  Created by Nicholas Raptis on 5/8/25.
//

import Foundation
import MathKit

class RingBuilderWeightPoint: MathKit.PointProtocol {
    typealias Point = MathKit.Math.Point
    typealias Vector = MathKit.Math.Vector
    var x = Float(0.0)
    var y = Float(0.0)
    var controlIndex = 0
    var point: Point {
        Point(x: x, y: y)
    }
}
