import SwiftUI


import SwiftUI

struct ContentView: View {
    @State private var linePoints: [CGPoint] = []
    @State private var showArrow: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("field")
                    .resizable()
                    .ignoresSafeArea()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            

                
                if linePoints.count > 1 {
                    ArrowPathWithHead(points: linePoints)
                        .stroke(Color.red, lineWidth: 4)
                        .opacity(showArrow ? 1 : 0)
                        .animation(.easeOut(duration: 0.25), value: showArrow)
                        .onDisappear {
                            linePoints.removeAll()
                        }
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
                        showArrow = false // Triggers fade and then disappearance
                    }
            )
        }
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
