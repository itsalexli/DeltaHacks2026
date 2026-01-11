import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0 // 0: Home, 1: Tasks, 2: Add, 3: Data
    @State private var tasks: [TaskItem] = []

    var body: some View {
        ZStack {
            Image("appbackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    if selectedTab == 0 { homeView }
                    else if selectedTab == 1 { TaskScreen(showTaskScreen: .constant(true)) }
                    else if selectedTab == 2 { Text("Add Task Screen").foregroundColor(.white) }
                    else { Text("Data Analytics").foregroundColor(.white) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Navigation Bar
                HStack {
                    Spacer()
                    navButton(icon: "house.fill", label: "Home", index: 0)
                    Spacer()
                    navButton(icon: "checklist", label: "Tasks", index: 1) // Swapped
                    Spacer()
                    navButton(icon: "plus.circle.fill", label: "Add", index: 2) // Swapped
                    Spacer()
                    navButton(icon: "chart.bar.fill", label: "Data", index: 3)
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.bottom, 35)
                .background(.ultraThinMaterial)
                .overlay(Rectangle().frame(height: 0.5).foregroundColor(.white.opacity(0.2)), alignment: .top)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear(perform: loadPreviewTasks)
    }
    
    var homeView: some View {
        VStack(spacing: 30) {
            Text("Taski").foregroundColor(.white).bold().font(.largeTitle).padding(.top, 100)
            Spacer()
            
            // Preview Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick Preview").font(.headline).foregroundColor(.white).padding(.horizontal, 25)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(tasks.prefix(3)) { task in
                            VStack(alignment: .leading) {
                                Text(task.title).bold().foregroundColor(.white).lineLimit(1)
                                Text(task.price).foregroundColor(.green).font(.subheadline)
                            }
                            .padding().frame(width: 160).background(.ultraThinMaterial).cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 25)
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    func navButton(icon: String, label: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(.system(size: 10))
            }
        }
        .foregroundColor(selectedTab == index ? .white : .white.opacity(0.4))
    }
    
    func loadPreviewTasks() {
        if let data = UserDefaults.standard.data(forKey: "savedTasks"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        }
    }
}

#Preview{
    ContentView()
}
