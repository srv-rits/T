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
            Button(action: {
                ContentView.createMnemonicAndKeys()
            }) {
                Text("CLICK ME")
                    .font(.largeTitle)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
    
    public static func createMnemonicAndKeys() {
        do {
            /// Get a Random Mnemonic of 24 Words
            /// Change wordCount parameter to get mnemonics of any custom word length
            // let mnemonic = try DefaultMnemonicProvider(seedFactory: SubstrateSeedFactory()).make(wordCount: 24).phrase
            
            // Use Your Own Mnemonic of 12 Words
            let mnemonic: String = "airport lion hip soon senior odor balcony session radar search chicken cave"

            let keyPair = try KeyPairFactory.sr25519.generate(
                phrase: mnemonic,
                passphrase: ""
            )

            let privateKey = keyPair.privateKey
            let publicKey = keyPair.publicKey
            
            let message = "Test"
            let messageHash = try Data(message.utf8).hashing.blake2b_256()

            let signedMessage = try keyPair.sign(message: messageHash)
            let result = try keyPair.verify(message: messageHash, signature: signedMessage)
            print(result)

            let polkadotAddress: String = try publicKey.ss58.address(type: 42)
            let accountID = try polkadotAddress.ss58.accountId()
            
            print(polkadotAddress)
            print(accountID.toHexString()) // Same as Public Key So No Use So Far

            print("0x\(privateKey.toHexString())")
            print("0x\(publicKey.toHexString())")
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
