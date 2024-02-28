//
//  ContentView.swift
//  T
//
//  Created by Sourav Mishra on 11/09/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Secure Enclave Demo")
                .font(.title)
                .padding()
            
            Button("Show Result") {
                // Uncomment to test key creation in secure enclave
                // let _ = makeAndStoreKey(name: "Sourav3")
                
                // Uncomment to test encryption and decryption of data
                // encryptData()
                
                // Uncomment to test signing and verifying the sign
                // Sign the hash like we do normally
                // Hash function isn't available here so I used plaintext directly
                // sign(data: "Hello".data(using: .utf8)!)
                
                generateSubstrateKeys()
            }
            .padding()
        }
    }
    
    func generateSubstrateKeys() {
        // Use Your Own Mnemonic of 24 Words
        // 5Di3HRA779SPEGkjrGw1SN22bPjFX1KmqLMgtSFpYk1idV7A

//        let mnemonic: String = "cruise owner unveil parrot coast gym opera avocado flock diesel able news farm pole visa piano powder help call refuse awake good trumpet perfect"
        
        do {
            let mnemonic = try DefaultMnemonicProvider(seedFactory: SubstrateSeedFactory()).make(wordCount: 24).phrase
            let keyPair = try KeyPairFactory.sr25519.generate(
                phrase: mnemonic,
                passphrase: ""
            )
            
            let privateKey = keyPair.privateKey
            let publicKey = keyPair.publicKey
            
            print("Substrate Private Key:", privateKey.toHexString())
            print("Substrate Public Key:", publicKey.toHexString())
            
            encryptData(dataToEncrypt: privateKey.toHexString())
        }
        
        catch {
            print("Error Generating Substrate Keypair From Mnemonics")
        }
    }
    
    func makeAndStoreKey(name: String, requiresBiometry: Bool = false) -> SecKey? {
        
        let flags: SecAccessControlCreateFlags
        if #available(iOS 11.3, *) {
            flags = requiresBiometry ?
            [.privateKeyUsage, .biometryCurrentSet] : .privateKeyUsage
        } else {
            flags = requiresBiometry ?
            [.privateKeyUsage, .touchIDCurrentSet] : .privateKeyUsage
        }
        let access =
        SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                        flags,
                                        nil)!
        let tag = name.data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String     : 256,
            kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : tag,
                kSecAttrAccessControl as String     : access
            ]
        ]
        
        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)
        //        print(privateKey!)
        
        // Load the private key once saved using the name/tag
        // let fetchedKey = loadKey(name: "Sourav2")!
        // print(fetchedKey)
        
        // Get Public Key From Private Key [Secure Enclave's]
        // let publicKey = getPubKey(privateKey: privateKey!)!
        // print(publicKey)
        encryptData()
        return privateKey
    }
    
    // THIS FUNCTION LOADS THE PRIVATE KEY ASSOCIATED WITH THE KEY'S NAME
    func loadKey(name: String) -> SecKey? {
        let tag = name.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecReturnRef as String             : true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        let _publicKey = SecKeyCopyPublicKey(item as! SecKey)!
        //        print(publicKey)
        
        return (item as! SecKey)
    }
    
    // THIS FUNCTION RETURNS THE PUBLIC KEY ASSOCIATED WITH THE CORRESPONDING PRIVATE KEY
    func getPubKey(privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }
    
    func encryptData(dataToEncrypt: String = "") {
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        let publicKey: SecKey = getPubKey(privateKey: loadKey(name: "Sourav3")!)!
        
        var error: Unmanaged<CFError>?
        let clearTextData = dataToEncrypt.data(using: .utf8)!
        let cipherTextData = SecKeyCreateEncryptedData(publicKey, algorithm, clearTextData as CFData, &error) as Data?
        
        print("Encrypted Data:", cipherTextData!.base64EncodedString())
        
        guard cipherTextData != nil else {
            print((error!.takeRetainedValue() as Error).localizedDescription)
            return
        }
        
        addToKeychain(encryptedData: cipherTextData!)
//        decryptData(dataToDecrypt: cipherTextData! as CFData)
    }
    
    func addToKeychain(encryptedData: Data) {
        let service = "com.secure.enclave.test"
        let account = "userPrivateKey"
        
        // Create the keychain query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: encryptedData
        ]
        
        // Delete any existing item with the same service and account (not required to do everytime, just once will be enough while adding for the first time)
        SecItemDelete(query as CFDictionary)
        
        // Add the new item to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Check if the addition was successful
        if status == errSecSuccess {
            print("Encrypted data added to Keychain successfully.")
        } else {
            print("Failed to add encrypted data to Keychain. Status code: \(status)")
        }
        
        retrieveFromKeychain()
    }
    
    func retrieveFromKeychain() {
        let service = "com.secure.enclave.test"
        let account = "userPrivateKey"
        
        // Create the keychain query dictionary for retrieval
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var retrievedData: AnyObject?
        
        // Retrieve the data from the keychain
        let status = SecItemCopyMatching(query as CFDictionary, &retrievedData)

        // Check if the retrieval was successful
        if status == errSecSuccess {
            print("Retrieved Data:", (retrievedData as? Data)!.base64EncodedString())
        } else {
            print("Failed to retrieve encrypted data from Keychain. Status code: \(status)")
            return
        }
        
        decryptData(dataToDecrypt: retrievedData as! CFData)
    }
    
    func decryptData(dataToDecrypt: CFData) {
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        
        // Don't create new thread if biometric auth is disabled for this
        DispatchQueue.global().async {
            var error: Unmanaged<CFError>?
            let clearTextData = SecKeyCreateDecryptedData(loadKey(name: "Sourav3")!, algorithm, dataToDecrypt, &error) as Data?
            DispatchQueue.main.async {
                guard clearTextData != nil else {
                    print((error!.takeRetainedValue() as Error).localizedDescription)
                    return
                }
                let clearText = String(decoding: clearTextData!, as: UTF8.self)
                print("Decrypted Data:", clearText, "\n")
            }
        }
    }
    
    func sign(data: Data) {
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256 // Use when signing a message directly
//        let algorithm: SecKeyAlgorithm = .ecdsaSignatureDigestX962SHA256 // Use when signing a hash(SHA 256)
        // Don't create new thread if biometric auth is disabled for this
        DispatchQueue.global().async {
            var error: Unmanaged<CFError>?
            let signature = SecKeyCreateSignature(loadKey(name: "Sourav3")!, algorithm, data as CFData, &error) as Data?
            DispatchQueue.main.async {
                guard signature != nil else {
                    print((error!.takeRetainedValue() as Error).localizedDescription)
                    return
                }
            }
            verify(signature: signature! as CFData)
        }
    }
    
    func verify(signature: CFData) {
        let publicKey = SecKeyCopyPublicKey(getPubKey(privateKey: loadKey(name: "Sourav3")!)!)!

        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

        let clearTextData = "Hello".data(using: .utf8)!
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(publicKey, algorithm, clearTextData as CFData, signature, &error)
        print(result)
    }
    
    
    public static func u8aToHex(_ value: Data, bitLength: Int = -1, isPrefixed: Bool = true) -> String {
        // This is not 100% correct since we support isPrefixed = false...
        let empty = isPrefixed ? "0x" : ""
        
        if value.isEmpty {
            return empty
        } else if bitLength > 0 {
            let length = Int(ceil(Double(bitLength) / 8.0))
            if value.count > length {
                let prefixPart = hex(value.subdata(in: 0..<length / 2), prefix: empty)
                let suffixPart = hex(value.subdata(in: value.count - length / 2..<value.count), prefix: "")
                return "\(prefixPart)…\(suffixPart)"
            }
        }
        
        return hex(value, prefix: empty)
    }

    public static func hex(_ data: Data, prefix: String) -> String {
        return data.map { String(format: "%02hhx", $0) }.reduce(prefix, +)
    }
    
    public static func createMnemonicAndKeys() {
        do {
            /// Get a Random Mnemonic of 24 Words
            /// Change wordCount parameter to get mnemonics of any custom word length
            // let mnemonic = try DefaultMnemonicProvider(seedFactory: SubstrateSeedFactory()).make(wordCount: 24).phrase
            
            // Use Your Own Mnemonic of 24 Words
            let mnemonic: String = "cruise owner unveil parrot coast gym opera avocado flock diesel able news farm pole visa piano powder help call refuse awake good trumpet perfect"
            
            let keyPair = try KeyPairFactory.sr25519.generate(
                phrase: mnemonic,
                passphrase: ""
            )
            // 5Di3HRA779SPEGkjrGw1SN22bPjFX1KmqLMgtSFpYk1idV7A
            let privateKey = keyPair.privateKey
            let publicKey = keyPair.publicKey
            let message2 =
"""
{"signature":{"signer":{"id":"5C4hrfjw9DjXZTzV3MwzrrAr9P1MJhSrvWGWqi1eSuyUpnhM"},"signature":{"ed25519":"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"},"era":{"immortalEra":"0x00"},"nonce":0,"tip":0},"method":{"callIndex":"0x0300","args":{"dest":{"id":"5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"},"value":1}}}
"""
            
            let message3 =
            """
            {"signature":{"signer":{"id":"5Di3HRA779SPEGkjrGw1SN22bPjFX1KmqLMgtSFpYk1idV7A"},"signature":{"sr25519":"0x4833c274883409ea47d2ac767baff236413c81fa9425e4feceaed33607956c34f6c2fdd02df42c43df8ecc66d36f38585ab7a19530943e7f5ad23efa23f61385"},"era":{"immortalEra":"0x00"},"nonce":0,"tip":0},"method":{"callIndex":"0x0300","args":{"dest":{"id":"5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY"},"value":1}}}
            """
            
            let m =
            """
            {{"method":"0x03010050b0dd0fe87381baf1ecc22851a664dc3951b19bd524edaf3af36db94a51075d022d310120546573744d656d6f","era":{"mortalEra":"0x4500"},"nonce":104,"tip":0,"specVersion":21,"transactionVersion":1,"genesisHash":"0xff59dd51c727560f504f25aaed829bf06b54c42c14ec132f7ad5c031cac51a55","blockHash":"0x89cf735d0ed6a24c67df48a53c346f909ad030a374aa5bcfbe13ee1c024c825d"}
            """.data(using: .utf8)!
            
            let m3 = "0x03010050b0dd0fe87381baf1ecc22851a664dc3951b19bd524edaf3af36db94a51075d022d310120546573744d656d6f2503bd01001500000001000000ff59dd51c727560f504f25aaed829bf06b54c42c14ec132f7ad5c031cac51a55dfcebbeee0df9a45a6719a49f3d80a63015a563bab456353b2f98475fb214b82".data(using: .utf8)!
            let messageHash = try m3.hashing.blake2b_256()
            //
            let a = Data([3,1,0,80,176,221,15,232,115,129,186,241,236,194,40,81,166,100,220,57,81,177,155,213,36,237,175,58,243,109,185,74,81,7,93,2,45,49,1,32,84,101,115,116,77,101,109,111,229,3,185,1,0,21,0,0,0,1,0,0,0,255,89,221,81,199,39,86,15,80,79,37,170,237,130,155,240,107,84,196,44,20,236,19,47,122,213,192,49,202,197,26,85,232,253,225,209,14,5,248,181,27,116,169,129,68,153,101,27,85,223,68,81,127,154,183,121,37,120,230,186,232,108,70,108])
//            let signedMessage = try keyPair.sign(message: a)
//            let hello = "hello".data(using: .utf8)!
//            let messageHash2 = try Data(hello.utf8).hashing.blake2b_256()
            let signedMessage = try keyPair.sign(message: m3 )
//            print("hello hash", messageHash2.toHexString())
            //            let result = try keyPair.verify(message: messageHash, signature: signedMessage)
            //            print(result)
            //
            //            let polkadotAddress: String = try publicKey.ss58.address(type: 42)
            //            let accountID = try polkadotAddress.ss58.accountId()
            //
            //            print(polkadotAddress)
            //            print(accountID.toHexString()) // Same as Public Key So No Use So Far
            //
            //            print("0x\(privateKey.toHexString())")
            //            print("0x\(publicKey.toHexString())")
            //
            //            print(messageHash.toHexString())
                        print(signedMessage.toHexString())
        
//            print(u8aToHex(message3.data(using: .utf8)!))
        }
        
        catch {
            print("\(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Data {
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// Primbon
