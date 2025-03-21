import SwiftUI

@MainActor
@Observable
class MediaCalendar {
    var instances: [Instance] = []
    var dates: [TimeInterval] = []

    var movies: [TimeInterval: [Movie]] = [:]
    var episodes: [TimeInterval: [Episode]] = [:]

    var isLoading: Bool = false
    var isLoadingFuture: Bool = false

    var error: API.Error?
    var errorBinding: Binding<Bool> { .init(get: { self.error != nil }, set: { _ in }) }

    let calendar: Calendar = Calendar.current

    let days: Int = 45

    func load() async {
        if isLoading {
            return
        }

        isLoading = true

        await fetch(start: addDays(-days, Date.now), end: addDays(days, Date.now))

        isLoading = false
    }

    func loadMoreDates() {
        if isLoadingFuture { return }
        guard let lastDate = dates.last else { return }
        Task { await loadFutureDates(lastDate) }
    }

    private func loadFutureDates(_ timestamp: TimeInterval) async {
        isLoadingFuture = true

        let date = Date(timeIntervalSince1970: timestamp)
        await fetch(start: date, end: addDays(days, date))

        isLoadingFuture = false
    }

    private func fetch(start: Date, end: Date) async {
        error = nil

        let start = calendar.startOfDay(for: start)
        let end = calendar.startOfDay(for: end)

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for instance in instances {
                    group.addTask {
                        if instance.type == .radarr {
                            try await self.fetchMovies(instance, start, end)
                        }

                        if instance.type == .sonarr {
                            try await self.fetchEpisodes(instance, start, end)
                        }
                    }
                }

                try await group.waitForAll()
            }

            insertDates(start, end)
        } catch is CancellationError {
            // do nothing
        } catch let apiError as API.Error {
            error = apiError

            leaveBreadcrumb(.error, category: "calendar", message: "Request failed", data: ["error": apiError])
        } catch {
            self.error = API.Error(from: error)
        }
    }

    private func addDays(_ days: Int, _ date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    private func insertDates(_ start: Date, _ end: Date) {
        guard start <= end else {
            fatalError("end < start")
        }

        var currentDay = start

        while currentDay <= end {
            if !dates.contains(currentDay.timeIntervalSince1970) {
                dates.append(currentDay.timeIntervalSince1970)
            }

            currentDay = addDays(1, currentDay)
        }
    }

    private func fetchMovies(_ instance: Instance, _ start: Date, _ end: Date) async throws {
        let movies = try await dependencies.api.movieCalendar(start, end, instance)

        for movie in movies {
            if let digitalRelease = movie.digitalRelease {
                maybeUpsertMovie(movie, digitalRelease)
            }

            if let physicalRelease = movie.physicalRelease {
                maybeUpsertMovie(movie, physicalRelease)
            }

            if let inCinemas = movie.inCinemas {
                maybeUpsertMovie(movie, inCinemas)
            }
        }
    }

    private func maybeUpsertMovie(_ movie: Movie, _ date: Date) {
        let day = calendar.startOfDay(for: date).timeIntervalSince1970

        if movies[day] == nil {
            movies[day] = []
        }

        guard let index = movies[day]!.firstIndex(where: { $0.id == movie.id }) else {
            movies[day]!.append(movie)
            return
        }

        if movies[day]![index] != movie {
            movies[day]![index] = movie
        }
    }

    private func fetchEpisodes(_ instance: Instance, _ start: Date, _ end: Date) async throws {
        let episodes = try await dependencies.api.episodeCalendar(start, end, instance)

        for episode in episodes {
            if let airDate = episode.airDateUtc {
                maybeUpsertEpisode(episode, airDate)
            }
        }
    }

    private func maybeUpsertEpisode(_ episode: Episode, _ date: Date) {
        let day = calendar.startOfDay(for: date).timeIntervalSince1970

        if episodes[day] == nil {
            episodes[day] = []
        }

        guard let index = episodes[day]!.firstIndex(where: { $0.id == episode.id }) else {
            episodes[day]!.append(episode)
            return
        }

        if episodes[day]![index] != episode {
            episodes[day]![index] = episode
        }
    }

    func today() -> TimeInterval {
        calendar.startOfDay(for: Date.now).timeIntervalSince1970
    }

    func reset() {
        instances = []
        dates = []
        movies = [:]
        episodes = [:]
    }

    // let futureCutoff: TimeInterval = {
    //     Date().timeIntervalSince1970 + (365 * 86_400)
    // }()

    // let loadingOffset: Int = {
    //     Platform.deviceType() == .phone ? 7 : 14
    // }()

    // func maybeLoadMoreDates(_ scrollPosition: TimeInterval?) {
    //     if isLoadingFuture || dates.isEmpty {
    //         return
    //     }
    //
    //     guard let timestamp = scrollPosition, timestamp < futureCutoff else {
    //         return
    //     }
    //
    //     let threshold = dates.count - loadingOffset
    //
    //     if !dates.indices.contains(threshold) {
    //         return
    //     }
    //
    //     if timestamp > dates[threshold] {
    //         Task {
    //             await loadFutureDates(dates.last!)
    //         }
    //     }
    // }
}

enum RelativeDate {
    case today
    case tomorrow
    case yesterday

    var label: String {
        switch self {
        case .today: String(localized: "Today")
        case .tomorrow: String(localized: "Tomorrow")
        case .yesterday: String(localized: "Yesterday")
        }
    }
}
