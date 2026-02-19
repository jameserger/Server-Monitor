//
//  PlanResponse.swift
//  Gravy Company LLC
//
//  Created by Gandalf on 4/20/25.
//

import Foundation

struct DiscountPlanResponse: Identifiable, Codable {
    var id: Int
    var name: String
    var description: String
    var discountsAllowed: Int
    var appleSubscriptionProductId: String?
    var appleOneTimeProductId: String?
    var errorMessage: String?
    var active: Bool?
    var period: Int?
}

extension DiscountResponse: Hashable {
    static func == (lhs: DiscountResponse, rhs: DiscountResponse) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
