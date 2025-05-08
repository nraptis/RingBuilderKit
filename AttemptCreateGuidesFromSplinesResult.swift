//
//  AttemptCreateGuidesFromSplinesResult.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 11/11/24.
//
//  Verified on 11/12/2024 by Nick Raptis
//

import Foundation

public struct PartialSuccessData {
    public let guideCountOverflow: Bool
    public let guidePointCountOverflow: Bool
    public let guidePointCountUnderflow: Bool
    public let numberOfGuidesAdded: Int
    public let invalid: Bool
    public init(guideCountOverflow: Bool, guidePointCountOverflow: Bool, guidePointCountUnderflow: Bool, numberOfGuidesAdded: Int, invalid: Bool) {
        self.guideCountOverflow = guideCountOverflow
        self.guidePointCountOverflow = guidePointCountOverflow
        self.guidePointCountUnderflow = guidePointCountUnderflow
        self.numberOfGuidesAdded = numberOfGuidesAdded
        self.invalid = invalid
    }
}

public enum AttemptCreateGuidesFromSplinesResult {
    case success(Int) // In this case, all guides were added...
    case successPartial(PartialSuccessData) // In this case, some guides were added...
    case failure // In this case, no guides were added...
    case selectedJiggleRequired
}
