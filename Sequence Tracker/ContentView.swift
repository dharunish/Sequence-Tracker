import SwiftUI

struct ContentView: View {
    @State private var linePoints: [CGPoint] = []
    @State private var showArrow: Bool = false
    @State private var savedLines: [[CGPoint]] = []
    @State private var files: [String] = loadFiles()
    @State private var selectedFile: String? = nil
    @State private var showFileView: Bool = true
    
    var body: some View {
        ZStack {
            if showFileView {
                FileListView(files: $files, onSelectFile: { file in
                    selectedFile = file
                    savedLines = loadFromFile(named: file)
                    showFileView = false
                }, onCreateFile: { newFile in
                    if !files.contains(newFile) {
                        files.append(newFile)
                        ContentView.saveFiles(files)
                    }
                })
            } else if let file = selectedFile {
                DrawingView(fileName: file, savedLines: $savedLines, linePoints: $linePoints, showArrow: $showArrow, onFilesButton: {
                    showFileView = true
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    static func loadFiles() -> [String] {
        let url = filesURL()
        if let data = try? Data(contentsOf: url),
           let files = try? JSONDecoder().decode([String].self, from: data) {
            return files
        }
        return []
    }

    static func saveFiles(_ files: [String]) {
        let url = filesURL()
        if let data = try? JSONEncoder().encode(files) {
            try? data.write(to: url)
        }
    }

    static func filesURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("files.json")
    }

    func loadFromFile(named file: String) -> [[CGPoint]] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file)
        if let data = try? Data(contentsOf: url),
           let lines = try? JSONDecoder().decode([[CGPoint]].self, from: data) {
            return lines
        }
        return []
    }
}

struct FileListView: View {
    @Binding var files: [String]
    @State private var newFileName: String = ""
    var onSelectFile: (String) -> Void
    var onCreateFile: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Saved Files")
                .font(.largeTitle)
                .padding()

            List {
                ForEach(files.indices, id: \.self) { index in
                    TextField("File name", text: Binding(
                        get: { files[index] },
                        set: { newValue in
                            let oldName = files[index]
                            let newName = newValue
                            if !newName.isEmpty {
                                renameFile(from: oldName, to: newName)
                                files[index] = newName
                                ContentView.saveFiles(files)
                            }
                        }
                    ))
                    .onTapGesture {
                        onSelectFile(files[index])
                    }
                }
            }

            HStack {
                TextField("New file name", text: $newFileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Create") {
                    let trimmed = newFileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onCreateFile(trimmed)
                        newFileName = ""
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    func renameFile(from old: String, to new: String) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let oldURL = dir.appendingPathComponent(old)
        let newURL = dir.appendingPathComponent(new)
        try? FileManager.default.moveItem(at: oldURL, to: newURL)
    }
    
}

struct DrawingView: View {
    let fileName: String
    @Binding var savedLines: [[CGPoint]]
    @Binding var linePoints: [CGPoint]
    @Binding var showArrow: Bool

    var onFilesButton: () -> Void

    @State private var showSavedLines = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("field")
                    .resizable()
                    .ignoresSafeArea()
                    //.edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                if linePoints.count > 1 {
                    ArrowPathWithHead(points: linePoints)
                        .stroke(Color.red, lineWidth: 4)
                        .opacity(showArrow ? 1 : 0)
                        .animation(.easeOut(duration: 0.25), value: showArrow)
                }

                if showSavedLines {
                    ForEach(savedLines.indices, id: \.self) { i in
                        ArrowPathWithHead(points: savedLines[i])
                            .stroke(Color.blue, lineWidth: 4)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Button(showSavedLines ? "Hide Lines" : "Show Lines") {
                            showSavedLines.toggle()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        Button("Files") {
                            onFilesButton()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
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
                        if !linePoints.isEmpty {
                            savedLines.append(linePoints)
                            saveLines(savedLines, to: fileName)
                        }
                        linePoints.removeAll()
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
    }

    func saveLines(_ lines: [[CGPoint]], to file: String) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(file)
        if let data = try? JSONEncoder().encode(lines) {
            try? data.write(to: url)
        }
    }
}

struct ArrowPathWithHead: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard points.count > 1 else { return path }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }

        let end = points[points.count - 1]
        let previous = points[points.count - 2]
        let dx = end.x - previous.x
        let dy = end.y - previous.y
        let angle = atan2(dy, dx)

        let arrowLength: CGFloat = 20
        let arrowAngle: CGFloat = .pi / 6

        let tip = end
        let left = CGPoint(
            x: tip.x - arrowLength * cos(angle - arrowAngle),
            y: tip.y - arrowLength * sin(angle - arrowAngle)
        )
        let right = CGPoint(
            x: tip.x - arrowLength * cos(angle + arrowAngle),
            y: tip.y - arrowLength * sin(angle + arrowAngle)
        )

        path.move(to: tip)
        path.addLine(to: left)
        path.move(to: tip)
        path.addLine(to: right)

        return path
    }
}

#Preview {
    ContentView()
}
