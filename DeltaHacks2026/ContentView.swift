import SwiftUI

struct ContentView: View {
    // Controls which view is visible to remove slide animation
    @State private var showTaskScreen = false
    @State private var tasks: [TaskItem] = [] // Stores tasks for the home screen preview
    
    var body: some View {
        ZStack {
            // Persistent Background
            Image("appbackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Main Content Area
                ZStack {
                    if showTaskScreen {
                        // Pass the binding so TaskScreen can dismiss itself
                        TaskScreen(showTaskScreen: $showTaskScreen)
                            .transition(.identity)
                    } else {
                        // HOME SCREEN CONTENT
                        VStack(spacing: 30) {
                            Text("Taski")
                                .foregroundColor(.white)
                                .bold()
                                .font(.largeTitle)
                                .padding(.top, 100)
                            
                            Spacer()
                            
                            Button(action: {
                                showTaskScreen = true
                            }) {
                                Text("Just Started")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 25)
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            // Task Preview Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Quick Preview")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 25)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        if tasks.isEmpty {
                                            Text("No active tasks found.")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                                .padding()
                                        } else {
                                            ForEach(tasks.prefix(3)) { task in
                                                VStack(alignment: .leading, spacing: 5) {
                                                    Text(task.title)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                    Text(task.price)
                                                        .foregroundColor(.green)
                                                        .font(.subheadline)
                                                }
                                                .padding()
                                                .frame(width: 160)
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(15)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 25)
                                }
                            }
                            .padding(.bottom, 40)
                        }
                        .transition(.identity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // MARK: - Custom Bottom Navigation Bar
                HStack {
                    Spacer()
                    
                    // Home Icon
                    navButton(icon: "house.fill", label: "Home", active: !showTaskScreen) {
                        showTaskScreen = false
                    }
                    
                    Spacer()
                    
                    // Add Icon
                    navButton(icon: "plus.circle.fill", label: "Add", active: false) {
                        // Action for Add
                    }
                    
                    Spacer()
                    
                    // NEW: Tasks Icon
                    navButton(icon: "checklist", label: "Tasks", active: showTaskScreen) {
                        showTaskScreen = true
                    }
                    
                    Spacer()
                    
                    // Data Icon
                    navButton(icon: "chart.bar.fill", label: "Data", active: false) {
                        // Action for Data
                    }
                    
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.bottom, 35)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.white.opacity(0.2)),
                    alignment: .top
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear(perform: loadPreviewTasks)
    }
    
    // Helper for Navigation Buttons
    func navButton(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label).font(.system(size: 10))
            }
        }
        .foregroundColor(active ? .white : .white.opacity(0.4))
    }
    
    // Load tasks for the Home screen preview
    func loadPreviewTasks() {
        if let data = UserDefaults.standard.data(forKey: "savedTasks"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        }
    }
}

#Preview {
    ContentView()
}
