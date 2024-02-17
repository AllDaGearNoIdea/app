import SwiftUI

struct MovieGridItem: View {
    var movie: Movie

    var body: some View {
        ZStack {
            poster
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contextMenu {
            MovieContextMenu(movie: movie)
        } preview: {
            poster.frame(width: 300, height: 450)
        }
        .background(.secondarySystemBackground)
        .overlay(alignment: .bottom) {
            if movie.exists {
                posterOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var poster: some View {
        CachedAsyncImage(url: movie.remotePoster, type: .poster)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .aspectRatio(
                CGSize(width: 150, height: 225),
                contentMode: .fill
            )
    }

    var posterOverlay: some View {
        HStack {
            Group {
                if movie.hasFile {
                    Image(systemName: "checkmark.circle.fill")
                } else if movie.isWaiting {
                    Image(systemName: "clock")
                } else if movie.monitored {
                    Image(systemName: "xmark.circle")
                }
            }.foregroundStyle(.white)

            Spacer()

            Image(systemName: "bookmark")
                .symbolVariant(movie.monitored ? .fill : .none)
                .foregroundStyle(.white)
        }
        .font(.body)
        .padding(.top, 36)
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
        .background {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func gridItemLayout() -> [GridItem] {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)]
        }

        if ProcessInfo.processInfo.isiOSAppOnMac {
            return [GridItem(.adaptive(minimum: 180, maximum: 200), spacing: 12)]
        }

        return [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 12)]
    }
}

struct MovieContextMenu: View {
    var movie: Movie

    var body: some View {
        let traktUrl = "https://trakt.tv/search/tmdb/\(movie.tmdbId)?id_type=movie"

        Link(destination: URL(string: traktUrl)!, label: {
            Label("Open in Trakt", systemImage: "arrow.up.right.square")
        })
    }
}

#Preview {
    let movies: [Movie] = PreviewData.load(name: "movies")
        .sorted { $0.year > $1.year }

    let gridItemLayout = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
    ]

    return ScrollView {
        LazyVGrid(columns: gridItemLayout, spacing: 12) {
            ForEach(movies) { movie in
                MovieGridItem(movie: movie)
            }
        }
        .padding(.top, 0)
        .scenePadding(.horizontal)
    }
    .withAppState()
}
