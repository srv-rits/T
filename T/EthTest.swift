//import SwiftUI
//
//struct Check: View {
//    var body: some View {
//        VStack {
//            Button(action: {
//                Check.createMnemonicAndKeys()
//            }) {
//                Text("CLICK ME")
//                    .font(.largeTitle)
//            }
//            .buttonStyle(PlainButtonStyle())
//        }
//        .padding()
//    }
//    
//    public static func createMnemonicAndKeys() {
//        do {
//            /// Get a Random Mnemonic of 24 Words
//            /// Change wordCount parameter to get mnemonics of any custom word length
//            // let mnemonic = try DefaultMnemonicProvider(seedFactory: SubstrateSeedFactory()).make(wordCount: 24).phrase
//            
//            // Use Your Own Mnemonic of 12 Words
//            let mnemonic: String = "state deal giraffe mouse approve tree token winner measure exchange rail seed"
//            let seed: Data = BlockChainKit.Mnemonic.createSeed(mnemonic)
//            let node = HDNode(seed: seed)
//            let privateKey = node.privateExtendedKey()
//            let publicKey = node.publicKey()
//            let address = Ethereum.address(privateKey: privateKey.toHexString())
//
//            print("0x\(privateKey.toHexString())")
//            print("0x\(publicKey.toHexString())")
//            print("\(address)")
//
//            
////            print(messageHash.toHexString())
//        }
//        catch {
//            print("\(error)")
//        }
//    }
//}
//
//struct Content_Previews: PreviewProvider {
//    static var previews: some View {
//        Check()
//    }
//}
