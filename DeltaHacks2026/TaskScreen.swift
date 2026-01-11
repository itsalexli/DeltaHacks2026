import SwiftUI
import Combine

// MARK: - Data Model
struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var price: String
    var biddingDate: Date
    var dueDate: Date
}

struct TaskScreen: View {
    // This binding fixes the "Argument passed to call that takes no arguments" error
    @Binding var showTaskScreen: Bool
    
    @State private var tasks: [TaskItem] = []
    @State private var userBalance: Double = 1250.00
    @State private var selectedTask: TaskItem? = nil
    @State private var bidInput: String = ""
    @State private var showBidError: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                // Header: Home button removed per request
                HStack {
                    Spacer()
                    Text("Available Tasks")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    
                    // Balance: Formatted to 2 decimal places
                    Text(String(format: "$%.2f", userBalance))
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.green)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(tasks) { task in
                            TaskRow(task: task)
                                .onTapGesture { openBidPopup(for: task) }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .blur(radius: selectedTask != nil ? 5 : 0)
            .disabled(selectedTask != nil)
            
            // MARK: - Bidding Popup
            if let task = selectedTask {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { closePopup() }
                
                VStack(spacing: 20) {
                    Text(task.title).font(.title2).bold().foregroundColor(.white)
                    Divider().background(Color.white.opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Buy Price: \(task.price)").foregroundColor(.green).bold()
                        Text("Your Balance: \(String(format: "$%.2f", userBalance))")
                            .foregroundColor(.white).font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("0.00", text: $bidInput)
                        .keyboardType(.decimalPad)
                        .onChange(of: bidInput) { newValue in
                            // Restrict to numbers and 2 decimal places
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered.contains(".") {
                                let parts = filtered.components(separatedBy: ".")
                                if parts.count > 2 {
                                    bidInput = String(filtered.prefix(filtered.count - 1))
                                } else if parts[1].count > 2 {
                                    bidInput = parts[0] + "." + parts[1].prefix(2)
                                } else { bidInput = filtered }
                            } else { bidInput = filtered }
                        }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(10).foregroundColor(.white)
                    
                    if showBidError {
                        Text("Bid must be lower than current price.").foregroundColor(.red).font(.caption)
                    }
                    
                    HStack(spacing: 15) {
                        Button("Close") { closePopup() }
                            .foregroundColor(.white).padding().frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3)).cornerRadius(10)
                        
                        Button("Bid") { placeBid() }
                            .bold().foregroundColor(.white).padding().frame(maxWidth: .infinity)
                            .background(Color.green).cornerRadius(10)
                    }
                }
                .padding(25).background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial)).padding(.horizontal, 30)
            }
        }
        .onAppear(perform: loadTasks)
        .padding()
    }
    
    func openBidPopup(for task: TaskItem) {
        selectedTask = task
        bidInput = ""
        showBidError = false
    }
    
    func closePopup() { withAnimation(.easeInOut(duration: 0.1)) { selectedTask = nil } }
    
    func placeBid() {
        guard let task = selectedTask, let bidValue = Double(bidInput),
              let currentPrice = Double(task.price.replacingOccurrences(of: "$", with: "")) else { return }
        
        if bidValue < currentPrice {
            // Note: userBalance remains unchanged per request
            updateTaskPrice(taskID: task.id, newPrice: bidValue)
            closePopup()
        } else { showBidError = true }
    }
    
    func updateTaskPrice(taskID: UUID, newPrice: Double) {
        if let index = tasks.firstIndex(where: { $0.id == taskID }) {
            tasks[index].price = "$" + String(format: "%.2f", newPrice)
        }
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
        }
    }
    
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "savedTasks"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        } else {
            tasks = [
                TaskItem(title: "Fix broken window", price: "$120.00", biddingDate: Date(), dueDate: Date().addingTimeInterval(86400 * 2)),
                TaskItem(title: "Mow the lawn", price: "$45.00", biddingDate: Date(), dueDate: Date().addingTimeInterval(86400)),
                TaskItem(title: "Assemble IKEA Desk", price: "$60.00", biddingDate: Date(), dueDate: Date().addingTimeInterval(86400 * 5))
            ]
        }
    }
}

struct TaskRow: View {
    let task: TaskItem
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title).font(.title3).bold().foregroundColor(.white)
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Bid by").font(.caption).foregroundColor(.gray)
                        Text(task.biddingDate, style: .date).font(.subheadline).foregroundColor(.white.opacity(0.9))
                    }
                    VStack(alignment: .leading) {
                        Text("Due").font(.caption).foregroundColor(.gray)
                        Text(task.dueDate, style: .date).font(.subheadline).foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            Spacer()
            Text(task.price).font(.headline).padding(.horizontal, 15).padding(.vertical, 10)
                .background(Color.green.opacity(0.8)).foregroundColor(.white).cornerRadius(10)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1)))
        .contentShape(Rectangle())
    }
}

#Preview {
    TaskScreen(showTaskScreen: .constant(true))
}
