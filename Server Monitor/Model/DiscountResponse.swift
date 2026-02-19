//
//  DiscountResponse.swift
//  Gravy Company LLC
//
//  Created by Gandalf on 12/1/24.
//
import Foundation

struct DiscountResponse: Identifiable, Codable {
    let id: Int
    let type: String
    let amount: Decimal?
    let originalAmount: Decimal?
    let startDateTime: String
    let endDateTime: String
    let frequency: String
    let message: String
    let code: String
    let errorMessage: String?
}
