import Foundation

/// JSON encoder/decoder configurados pro formato que o Supabase (PostgREST) usa:
/// timestamps ISO8601 com fração de segundos, e datas simples "yyyy-MM-dd".
enum SupabaseJSON {
    static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoPlain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parseTimestamp(_ string: String) -> Date? {
        isoWithFractional.date(from: string) ?? isoPlain.date(from: string)
    }

    static func formatTimestamp(_ date: Date) -> String {
        isoWithFractional.string(from: date)
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = parseTimestamp(string) { return date }
            if let date = dateOnlyFormatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data inválida: \(string)")
        }
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatTimestamp(date))
        }
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}
