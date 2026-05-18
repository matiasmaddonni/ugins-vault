import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lock.shield")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("UginsVault")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
