// SearchOverlay.swift
import SwiftUI

struct SearchOverlay: View {
    @Environment(SearchRouter.self) private var searchRouter
    let maxResults: Int

    var body: some View {
        ZStack {
            // Dimmed background that closes the overlay on tap
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    searchRouter.close()
                }

            // Simple placeholder panel for search UI
            VStack(spacing: 12) {
                HStack {
                    Text("Search")
                        .font(.title2).bold()
                    Spacer()
                    Button {
                        searchRouter.close()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .buttonStyle(.plain)
                }

                Text("Max results: \(maxResults)")
                    .foregroundStyle(.secondary)

                // Placeholder search field
                TextField("Type to search…", text: .constant(""))
                    .textFieldStyle(.roundedBorder)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: 600, maxHeight: 360, alignment: .topLeading)
            .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            }
            .shadow(radius: 12)
            .padding()
        }
    }
}

#Preview {
    let router = SearchRouter()
    router.isPresented = true
    return SearchOverlay(maxResults: 50)
        .environment(router)
}
