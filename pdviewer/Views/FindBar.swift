import SwiftUI

/// Find bar shown above the page view when `controller.isFindBarVisible`.
struct FindBar: View {
    let controller: ReaderController
    @FocusState private var fieldFocused: Bool

    var body: some View {
        @Bindable var search = controller.search
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Find in document", text: $search.query)
                    .textFieldStyle(.roundedBorder)
                    .focused($fieldFocused)
                    .onSubmit { submit() }
                    .onExitCommand { close() }
                    .accessibilityLabel("Find")
                    .frame(maxWidth: 280)
                Text(search.statusText)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .leading)
                    .accessibilityLabel("Search status")
                    .accessibilityValue(search.statusText)
                Button { search.previous() } label: { Image(systemName: "chevron.up") }
                    .accessibilityLabel("Previous match")
                    .disabled(search.results.isEmpty)
                Button { search.next() } label: { Image(systemName: "chevron.down") }
                    .accessibilityLabel("Next match")
                    .disabled(search.results.isEmpty)
                Spacer(minLength: 0)
                Button("Done") { close() }
                    .accessibilityLabel("Close find bar")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            Divider()
        }
        .background(.bar)
        .onAppear { fieldFocused = true }
        .onChange(of: search.focusRequest) { fieldFocused = true }
    }

    /// Enter goes to the next match; Shift+Enter to the previous.
    private func submit() {
        if NSEvent.modifierFlags.contains(.shift) {
            controller.search.previous()
        } else {
            controller.search.next()
        }
        fieldFocused = true
    }

    private func close() {
        controller.isFindBarVisible = false
        controller.search.clear()
    }
}
