//
//  KeychainError.swift
//  SwiftBench
//
//  Created by Arya Mirsepasi on 21.12.25.
//

import Foundation

enum KeychainError: Error {
    case emptyKey
    case storeFailed(OSStatus)
    case deleteFailed(OSStatus)
}
