import SwiftUI

/// Sheet for jumping to a page number (1-based in the UI).
struct GoToPageSheet: View {
    let controller: ReaderController
    @State private var text = ""
    @FocusState private var focused: Bool

    private var page: Int? {
        guard let number = Int(text.trimmingCharacters(in: .whitespaces)),
              (1...max(controller.pageCount, 1)).contains(number) else { return nil }
        return number
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Go to Page").font(.headline)
            TextField("Page 1\u{2013}\(controller.pageCount)", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .focused($focused)
                .onSubmit(go)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { controller.isGoToPagePresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Go", action: go)
                    .keyboardShortcut(.defaultAction)
                    .disabled(page == nil)
            }
        }
        .padding(20)
        .onAppear { focused = true }
    }

    private func go() {
        guard let page else { return }
        controller.history.jump(to: page - 1)
        controller.isGoToPagePresented = false
    }
}
