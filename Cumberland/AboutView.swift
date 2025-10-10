// AboutView.swift
import SwiftUI

struct AboutView: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Cumberland"
    }

    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        if short.isEmpty && build.isEmpty {
            return ""
        } else if build.isEmpty {
            return "Version \(short)"
        } else {
            return "Version \(short) (\(build))"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            appIcon
                .frame(width: 96, height: 96)
                .cornerRadius(20)
                .shadow(radius: 8)

            VStack(spacing: 4) {
                Text(appName)
                    .font(.title2).bold()
                if !versionString.isEmpty {
                    Text(versionString)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 2) {
                Text("Author")
                    .font(.subheadline).bold()
                Text("Michael Stoddard")
                    .font(.body)
            }
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 260, alignment: .top)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var appIcon: some View {
        #if os(macOS)
        if let image = NSApp.applicationIconImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Color.clear
        }
        #else
        // Fallback for other platforms if ever shown
        Image(systemName: "app.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
        #endif
    }
}

#Preview {
    AboutView()
        .frame(width: 480, height: 300)
}
