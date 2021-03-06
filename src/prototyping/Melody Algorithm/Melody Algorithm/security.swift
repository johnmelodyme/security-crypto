//  security.swift
//  Melody Algorithm
//  Created by John Melody on 05/06/2020.
//  Copyright © 2020 John Melody. All rights reserved.
//

import CommonCrypto
import Foundation

//func main() {
//    let key = try derivateKey(passphrase: "hello", salt: "world")
//    let iv = Data([1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6])
//    let input = Data("foobar".utf8)
//    let ciphertext = try encrypt(data: input, key: key, iv: iv)
//    let plain = try decrypt(data: ciphertext, key: key)
//    print(plain == input) // true
//}


// Raise Exception:
enum Error: Swift.Error {
    case encryptionError(status: CCCryptorStatus)
    case decryptionError(status: CCCryptorStatus)
    case keyDerivationError(status: CCCryptorStatus)
}

func encrypt(data: Data, key: Data, iv: Data) throws -> Data {
    // Output buffer (with padding)
    let outputLength = data.count + kCCBlockSizeAES128
    var outputBuffer = Array<UInt8> (repeating: 0, count: outputLength)
    var numBytesEncrypted = 0
    let status = CCCrypt(CCOperation(kCCEncrypt),
                         CCAlgorithm(kCCAlgorithmAES),
                         CCOptions(kCCOptionPKCS7Padding),
                         Array(key),
                         kCCKeySizeAES256,
                         Array(iv),
                         Array(data),
                         data.count,
                         &outputBuffer,
                         outputLength,
                         &numBytesEncrypted)
    guard status == kCCSuccess else {
        throw Error.encryptionError(status: status)
    }
    let outputBytes = iv + outputBuffer.prefix(numBytesEncrypted)
    return Data(outputBytes)
}

func decrypt(data cipherData: Data, key: Data) throws -> Data {
    // Split IV and cipher text
    let iv = cipherData.prefix(kCCBlockSizeAES128)
    let cipherTextBytes = cipherData
                           .suffix(from: kCCBlockSizeAES128)
    let cipherTextLength = cipherTextBytes.count
    // Output buffer
    var outputBuffer = Array<UInt8>(repeating: 0,
                                    count: cipherTextLength)
    var numBytesDecrypted = 0
    let status = CCCrypt(CCOperation(kCCDecrypt),
                         CCAlgorithm(kCCAlgorithmAES),
                         CCOptions(kCCOptionPKCS7Padding),
                         Array(key),
                         kCCKeySizeAES256,
                         Array(iv),
                         Array(cipherTextBytes),
                         cipherTextLength,
                         &outputBuffer,
                         cipherTextLength,
                         &numBytesDecrypted)
    guard status == kCCSuccess else {
        throw Error.decryptionError(status: status)
    }
    // Discard padding
    let outputBytes = outputBuffer.prefix(numBytesDecrypted)
    return Data(outputBytes)
}

func derivateKey(passphrase: String, salt: String) throws -> Data {
    let rounds = UInt32(45_000)
    var outputBytes = Array<UInt8>(repeating: 0,
                                   count: kCCKeySizeAES256)
    let status = CCKeyDerivationPBKDF(
        CCPBKDFAlgorithm(kCCPBKDF2),
        passphrase,
        passphrase.utf8.count,
        salt,
        salt.utf8.count,
        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
        rounds,
        &outputBytes,
        kCCKeySizeAES256)
    
    guard status == kCCSuccess else {
        throw Error.keyDerivationError(status: status)
    }
    return Data(outputBytes)
}
