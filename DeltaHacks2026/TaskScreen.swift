import SwiftUI
import Combine

// MARK: - Data Model
// Note: If you have this defined in a separate shared file, remove it from here.
struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var price: String
    var biddingDate: Date
    var dueDate: Date
}

struct TaskScreen: View {
    @Binding var showTaskScreen: Bool
    
    @State private var tasks: [TaskItem] = []
    @State private var userBalance: Double = 1250.00
    @State private var selectedTask: TaskItem? = nil
    @State private var bidInput: String = ""
    @State private var showBidError: Bool = false
    
    // Sheet State for Adding Task
    @State private var showAddTaskSheet = false
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeNow = Date()
    
    var body: some View {
        ZStack {
            // MARK: Main Content
            VStack {
                // Header
                HStack {
                    Spacer()
                    Text("Available Tasks")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    
                    // Balance
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
                            TaskRow(task: task, currentTime: timeNow)
                                .onTapGesture { openBidPopup(for: task) }
                        }
                        // Spacer for FAB
                        Color.clear.frame(height: 80)
                    }
                    .padding()
                }
                Spacer()
            }
            .blur(radius: selectedTask != nil ? 5 : 0)
            .disabled(selectedTask != nil)
            
            // MARK: - Floating Add Button
            if selectedTask == nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddTaskSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 55, height: 55)
                                .foregroundColor(.green)
                                .background(Circle().fill(.white))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                        }
                        .padding(.trailing, 25)
                        .padding(.bottom, 20)
                    }
                }
            }

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
                            filterDecimalInput(newValue: newValue, binding: $bidInput)
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
        .onReceive(timer) { input in timeNow = input }
        .padding()
        // Add Task Sheet
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskView(tasks: $tasks)
        }
    }
    
    // Helper for decimal filtering
    func filterDecimalInput(newValue: String, binding: Binding<String>) {
        let filtered = newValue.filter { "0123456789.".contains($0) }
        if filtered.contains(".") {
            let parts = filtered.components(separatedBy: ".")
            if parts.count > 2 {
                binding.wrappedValue = String(filtered.prefix(filtered.count - 1))
            } else if parts[1].count > 2 {
                binding.wrappedValue = parts[0] + "." + parts[1].prefix(2)
            } else { binding.wrappedValue = filtered }
        } else { binding.wrappedValue = filtered }
    }
    
    // MARK: - Logic Functions
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
                TaskItem(title: "Fix broken window", price: "$120.00", biddingDate: Date(), dueDate: Date().addingTimeInterval(86400 * 2 + 3600)),
                TaskItem(title: "Mow the lawn", price: "$45.00", biddingDate: Date(), dueDate: Date().addingTimeInterval(86400 * 1 + 1800)),
                TaskItem(title: "Assemble IKEA Desk", price: "$60.00", biddingDate: Date(), dueDate: Date().addingTimeInterval(86400 * 5 + 7200))
            ]
        }
    }
}

// MARK: - Subviews
struct TaskRow: View {
    let task: TaskItem
    var currentTime: Date = Date()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                // Title & Price
                HStack(spacing: 10) {
                    Text(task.title)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text(task.price)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // Dates & Countdown
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Bid by").font(.caption).foregroundColor(.gray)
                        Text(task.biddingDate, style: .date).font(.subheadline).foregroundColor(.white.opacity(0.9))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Time Left").font(.caption).foregroundColor(.gray)
                        Text(getCountdownString(to: task.dueDate))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.red.opacity(0.8))
                            .bold()
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1)))
        .contentShape(Rectangle())
    }
    
    func getCountdownString(to endDate: Date) -> String {
        let calendar = Calendar.current
        if currentTime >= endDate { return "00d : 00h : 00m : 00s" }
        
        let components = calendar.dateComponents([.day, .hour, .minute, .second], from: currentTime, to: endDate)
        return String(format: "%02dd : %02dh : %02dm : %02ds", components.day ?? 0, components.hour ?? 0, components.minute ?? 0, components.second ?? 0)
    }
}

// MARK: - Custom Styled Add Task View
struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var tasks: [TaskItem]
    
    @State private var title = ""
    @State private var price = ""
    @State private var dueDate = Date().addingTimeInterval(86400) // Default tomorrow
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                Text("Add New Task")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Divider().background(Color.white.opacity(0.3))
                
                // Inputs
                VStack(alignment: .leading, spacing: 15) {
                    
                    // Task Title Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Task Title").font(.caption).foregroundColor(.gray)
                        TextField("e.g. Clean Garage", text: $title)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // Price Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Price").font(.caption).foregroundColor(.gray)
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .onChange(of: price) { newValue in
                                filterDecimalInput(newValue: newValue)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                    
                    // Date Input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Due Date").font(.caption).foregroundColor(.gray)
                        DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark) // Forces dark mode picker
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                HStack(spacing: 15) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    Button(action: { saveTask() }) {
                        Text("Save Task")
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(title.isEmpty || price.isEmpty ? Color.green.opacity(0.3) : Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(title.isEmpty || price.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.fraction(0.65)]) // Makes the sheet height fit content better
        .presentationDragIndicator(.visible)
    }
    
    // Logic: Restrict to Numbers and 2 Decimal Places
    func filterDecimalInput(newValue: String) {
        let filtered = newValue.filter { "0123456789.".contains($0) }
        if filtered.contains(".") {
            let parts = filtered.components(separatedBy: ".")
            if parts.count > 2 {
                price = String(filtered.prefix(filtered.count - 1))
            } else if parts[1].count > 2 {
                price = parts[0] + "." + parts[1].prefix(2)
            } else { price = filtered }
        } else { price = filtered }
    }
    
    func saveTask() {
        var finalPrice = price.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalPrice.hasPrefix("$") {
            finalPrice = "$\(finalPrice)"
        }
        
        let newTask = TaskItem(title: title, price: finalPrice, biddingDate: Date(), dueDate: dueDate)
        tasks.append(newTask)
        
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
        }
        
        dismiss()
    }
}

#Preview {
    TaskScreen(showTaskScreen: .constant(true))
}
