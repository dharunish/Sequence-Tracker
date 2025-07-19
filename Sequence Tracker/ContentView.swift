import SwiftUI

struct ContentView: View {
    @State private var linePoints: [CGPoint] = []
    @State private var showArrow: Bool = false
    @State private var savedLines: [[CGPoint]] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("field")
                    .resizable()
                    .ignoresSafeArea()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Show current drawing line
                if linePoints.count > 1 {
                    ArrowPathWithHead(points: linePoints)
                        .stroke(Color.red, lineWidth: 4)
                        .opacity(showArrow ? 1 : 0)
                        .animation(.easeOut(duration: 0.25), value: showArrow)
                        

                }

                // Show all saved lines
                ForEach(savedLines.indices, id: \.self) { i in
                    ArrowPathWithHead(points: savedLines[i])
                        .stroke(Color.blue, lineWidth: 4)
                }

                VStack {
                    Spacer()
                    HStack {
                        Button("Load Saved") {
                            loadSavedLines()
                        }
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(8)
                        .foregroundColor(.white)

                        Button("Clear Saved") {
                            clearSavedLines()
                        }
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !showArrow {
                            showArrow = true
                            linePoints = [value.location]
                        } else {
                            linePoints.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        showArrow = false
                        saveLine(points: linePoints)
                        linePoints.removeAll()
                    }
            )
        }
    }

    // MARK: - File Handling

    func saveLine(points: [CGPoint]) {
        var current = loadFromFile()
        current.append(points)
        if let data = try? JSONEncoder().encode(current) {
            try? data.write(to: linesURL())
        }
        //savedLines = current
        //print(savedLines)
    }

    func loadSavedLines() {
        savedLines = loadFromFile()
    }

    func clearSavedLines() {
        savedLines.removeAll()
        try? FileManager.default.removeItem(at: linesURL())
    }

    func loadFromFile() -> [[CGPoint]] {
        guard let data = try? Data(contentsOf: linesURL()),
              let decoded = try? JSONDecoder().decode([[CGPoint]].self, from: data)
        else {
            print("No saved lines found.")
            return []
        }
        return decoded
    }

    func linesURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("lines.json")
    }
}


struct ArrowPathWithHead: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Draw the path
        guard points.count > 1 else { return path }
        path.addLines(points)

        // Arrowhead
        if let end = points.last, let prev = points.dropLast().last {
            let angle = atan2(end.y - prev.y, end.x - prev.x)
            let arrowLength: CGFloat = 20
            let arrowAngle: CGFloat = .pi / 6

            let point1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )

            let point2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )

            path.move(to: end)
            path.addLine(to: point1)

            path.move(to: end)
            path.addLine(to: point2)
        }

        return path
    }
}
#Preview {
    ContentView()
}
