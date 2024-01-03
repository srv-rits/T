/**
 *
 * Copyright 2023 SUBSTRATE LABORATORY LLC <info@sublab.dev>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import Bip39
import Foundation
import UncommonCrypto

// Never Ever Change These Values!
private let defaultPassphrase = "mnemonic"
private let scryptN = 16384
private let scryptR = 8
private let scryptP = 1
private let seedBytes = 64

public final class SubstrateSeedFactory: SeedFactory {
    public init() {}
    
    public func deriveSeed(mnemonic: Mnemonic, passphrase: String) throws -> Data {
        enum SeedDerivationError: Error {
            case SaltStringToDataError
        }
        
        guard let saltData = (defaultPassphrase + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            throw SeedDerivationError.SaltStringToDataError
        }

        var saltByteArray = [UInt8](repeating: 0, count: saltData.count)
        saltByteArray = saltData.withUnsafeBytes { saltBytes in
            return [UInt8](saltBytes)
        }

        let mnemonicData = mnemonic.entropy
        var mnemonicByteArray = [UInt8](repeating: 0, count: mnemonicData.count)
        mnemonicByteArray = mnemonicData.withUnsafeBytes { mnemonicBytes in
            return [UInt8](mnemonicBytes)
        }
        
        return try Data(PBKDF2.derive(type: .sha512, password: mnemonicByteArray, salt: saltByteArray))
    }
}
