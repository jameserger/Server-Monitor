//
//  SignInResponse.swift
//  Gravy Company LLC
//
//  Created by Gandalf on 11/20/24.
//
import Foundation

struct ProvisionalUserResponse: Decodable {
    
    let accessToken: String
    let refreshToken: String?
    let expEpochSeconds: Int?
    let errorMessage: String?
    
}
