import SwiftUI

struct ContentView: View {
    @State private var linePoints: [CGPoint] = []
    @State private var showLine: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background field image
                Image("field")
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Line drawn by finger
                if showLine && linePoints.count > 1 {
                    Path { path in
                        path.addLines(linePoints)
                    }
                    .stroke(Color.red, lineWidth: 4)
                    .transition(.opacity)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !showLine {
                            showLine = true
                            linePoints = [value.location]
                        } else {
                            linePoints.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 2.0)) {
                            showLine = false
                            linePoints.removeAll()
                        }

                    }
            )
        }
        .ignoresSafeArea()
    }
}





#Preview {
    ContentView()
}
