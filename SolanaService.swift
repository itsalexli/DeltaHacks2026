import Foundation
import Combine
import SolanaSwift

class SolanaService: ObservableObject {
    @Published var isProcessing = false
    @Published var statusMessage = "Ready to connect"
    @Published var balance: Double = 0.0
    
    // MARK: - Configuration
    // Update this IP to your Mac's LAN IP for local validator
    private let endpointURL = "http://172.18.78.52:8899"
    private let programId = "TrSvGRr4F3aVXvyGMKQWaWYwFHawWcDaiL5WqUL6DVU"
    
    // Solana SDK Clients
    private var apiClient: JSONRPCAPIClient?
    private var blockchainClient: BlockchainClient?
    private var keyPair: KeyPair?
    
    init() {
        setupSolana()
    }
    
    func setupSolana() {
        // Create a custom endpoint pointing to our local validator
        let endpoint = APIEndPoint(
            address: endpointURL,
            network: .mainnetBeta
        )
        
        let api = JSONRPCAPIClient(endpoint: endpoint)
        self.apiClient = api
        self.blockchainClient = BlockchainClient(apiClient: api)
        
        // Demo mnemonic - in a real app, use Keychain
        let mnemonic = "route clerk illness curve couple divorce hello verify visual senior moral cover"
        let words = mnemonic.components(separatedBy: " ")
        
        Task {
            do {
                // Restore KeyPair from mnemonic phrase
                keyPair = try await KeyPair(phrase: words, network: .mainnetBeta, derivablePath: .default)
                print("Wallet: \(keyPair?.publicKey.base58EncodedString ?? "Unknown")")
                await updateBalance()
            } catch {
                print("Error creating account: \(error)")
                await MainActor.run { self.statusMessage = "Wallet Error" }
            }
        }
    }
    
    @MainActor
    func updateBalance() async {
        guard let apiClient = apiClient, let keyPair = keyPair else { return }
        do {
            let bal = try await apiClient.getBalance(account: keyPair.publicKey.base58EncodedString)
            self.balance = Double(bal) / 1_000_000_000.0
            self.statusMessage = "Connected: \(String(format: "%.2f", self.balance)) SOL"
        } catch {
            self.statusMessage = "Balance Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Public Actions
    
    func depositSOL(amount: Double, teamId: UInt64) {
        Task { await performDeposit(amount: amount, teamId: teamId) }
    }
    
    func placeBid(lamports: UInt64, taskId: UInt64, teamId: UInt64) {
        Task { await performBid(lamports: lamports, taskId: taskId, teamId: teamId) }
    }
    
    // MARK: - Internal Transaction Logic
    
    @MainActor
    private func performDeposit(amount: Double, teamId: UInt64) async {
        guard let blockchainClient = blockchainClient, let keyPair = keyPair else { return }
        isProcessing = true
        statusMessage = "Depositing..."
        
        do {
            let lamports = UInt64(amount * 1_000_000_000)
            let programKey = try PublicKey(string: programId)
            
            // Derive PDAs: team = ["team", authority, team_id]
            let teamIdBytes = withUnsafeBytes(of: teamId.littleEndian) { Array($0) }
            let (teamPDA, _) = try PublicKey.findProgramAddress(
                seeds: ["team".data(using: .utf8)!, keyPair.publicKey.data, Data(teamIdBytes)],
                programId: programKey
            )
            
            // vault = ["vault", team_key]
            let (vaultPDA, _) = try PublicKey.findProgramAddress(
                seeds: ["vault".data(using: .utf8)!, teamPDA.data],
                programId: programKey
            )
            
            // Instruction Data: discriminator (deposit) + lamports
            var data = Data([242, 35, 198, 137, 82, 225, 242, 182])
            data.append(contentsOf: withUnsafeBytes(of: lamports.littleEndian) { Array($0) })
            
            let instruction = TransactionInstruction(
                keys: [
                    AccountMeta(publicKey: teamPDA, isSigner: false, isWritable: false),
                    AccountMeta(publicKey: vaultPDA, isSigner: false, isWritable: true),
                    AccountMeta(publicKey: keyPair.publicKey, isSigner: true, isWritable: true),
                    AccountMeta(publicKey: keyPair.publicKey, isSigner: true, isWritable: false),
                    AccountMeta(publicKey: SystemProgram.id, isSigner: false, isWritable: false)
                ],
                programId: programKey,
                data: [UInt8](data)
            )
            
            let preparedTx = try await blockchainClient.prepareTransaction(
                instructions: [instruction],
                signers: [keyPair],
                feePayer: keyPair.publicKey
            )
            
            let txId = try await blockchainClient.sendTransaction(preparedTransaction: preparedTx)
            statusMessage = "Success! Tx: \(txId.prefix(8))..."
            await updateBalance()
            
        } catch {
            statusMessage = "Deposit Failed: \(error.localizedDescription)"
            print("Deposit Error: \(error)")
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func performBid(lamports: UInt64, taskId: UInt64, teamId: UInt64) async {
        guard let blockchainClient = blockchainClient, let keyPair = keyPair else { return }
        isProcessing = true
        statusMessage = "Placing Bid..."
        
        do {
            let programKey = try PublicKey(string: programId)
            
            // Derive team PDA (assuming current user is team authority for demo)
            let teamIdBytes = withUnsafeBytes(of: teamId.littleEndian) { Array($0) }
            let (teamPDA, _) = try PublicKey.findProgramAddress(
                seeds: ["team".data(using: .utf8)!, keyPair.publicKey.data, Data(teamIdBytes)],
                programId: programKey
            )
            
            // Derive task PDA
            let taskIdBytes = withUnsafeBytes(of: taskId.littleEndian) { Array($0) }
            let (taskPDA, _) = try PublicKey.findProgramAddress(
                seeds: ["task".data(using: .utf8)!, teamPDA.data, Data(taskIdBytes)],
                programId: programKey
            )
            
            // Instruction Data: discriminator (place_bid) + lamports
            var data = Data([238, 77, 148, 91, 200, 151, 92, 146])
            data.append(contentsOf: withUnsafeBytes(of: lamports.littleEndian) { Array($0) })
            
            let instruction = TransactionInstruction(
                keys: [
                    AccountMeta(publicKey: teamPDA, isSigner: false, isWritable: false),
                    AccountMeta(publicKey: taskPDA, isSigner: false, isWritable: true),
                    AccountMeta(publicKey: keyPair.publicKey, isSigner: true, isWritable: false)
                ],
                programId: programKey,
                data: [UInt8](data)
            )
            
            let preparedTx = try await blockchainClient.prepareTransaction(
                instructions: [instruction],
                signers: [keyPair],
                feePayer: keyPair.publicKey
            )
            
            let txId = try await blockchainClient.sendTransaction(preparedTransaction: preparedTx)
            statusMessage = "Bid Placed! Tx: \(txId.prefix(8))..."
            
        } catch {
            statusMessage = "Bid Failed: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}
