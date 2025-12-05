import Foundation

struct YouTubeVideo: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailUrl: String
    let channelTitle: String
    let publishedAt: String
    let duration: String?
    let viewCount: String?
    
    var publishedDate: Date? {
        ISO8601DateFormatter().date(from: publishedAt)
    }
    
    var formattedPublishedDate: String {
        guard let date = publishedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "" }
        let pattern = "PT(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        guard let match = regex?.firstMatch(in: duration, options: [], range: NSRange(location: 0, length: duration.utf16.count)) else {
            return duration
        }
        var hours = ""
        var minutes = ""
        var seconds = ""
        if let range = Range(match.range(at: 1), in: duration) { hours = String(duration[range]) }
        if let range = Range(match.range(at: 2), in: duration) { minutes = String(duration[range]) }
        if let range = Range(match.range(at: 3), in: duration) { seconds = String(duration[range]) }
        if !hours.isEmpty {
            return "\(hours):\(minutes.padding(toLength: 2, withPad: "0", startingAt: 0)):\(seconds.padding(toLength: 2, withPad: "0", startingAt: 0))"
        } else if !minutes.isEmpty {
            return "\(minutes):\(seconds.padding(toLength: 2, withPad: "0", startingAt: 0))"
        } else {
            return "0:\(seconds.padding(toLength: 2, withPad: "0", startingAt: 0))"
        }
    }
    
    var formattedViewCount: String {
        guard let count = viewCount, let intCount = Int(count) else { return "" }
        if intCount >= 1_000_000 {
            return String(format: "%.1fM views", Double(intCount) / 1_000_000.0)
        } else if intCount >= 1_000 {
            return String(format: "%.1fK views", Double(intCount) / 1_000.0)
        } else {
            return "\(intCount) views"
        }
    }
    
    var youtubeURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(id)")
    }
}

struct YouTubeVideosResponse: Codable {
    let videos: [YouTubeVideo]

    private enum CodingKeys: String, CodingKey { case videos }

    init(videos: [YouTubeVideo]) {
        self.videos = videos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedVideos = try? container.decode([YouTubeVideo].self, forKey: .videos) {
            self.videos = decodedVideos
        } else {
            self.videos = []
        }
    }
}
