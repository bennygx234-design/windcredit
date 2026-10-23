import Foundation

// Counts nearby single-family homes and how many predate the 2002 building code.
// Data: Florida statewide parcel layer (DOR tax roll).
struct Neighborhood: Codable, Equatable {
    var homes: Int
    var olderHomes: Int
    var olderShare: Double { homes > 0 ? Double(olderHomes) / Double(homes) : 0 }

    func dollarsIfQuarterMissing(perHome: Int) -> Int {
        DiscountEngine.roundTo50(Double(olderHomes) * 0.25 * Double(perHome))
    }

    static let sample = Neighborhood(homes: 391, olderHomes: 377)
}

struct NeighborhoodService {
    var session: URLSession = .county
    private static let layer = "https://services9.arcgis.com/Gh9awoU677aKree0/arcgis/rest/services/Florida_Statewide_Cadastral/FeatureServer/0/query"

    // ~quarter mile each way. (Distance buffers error out on this service, so use a box.)
    static let latSpan = 0.0036, lonSpan = 0.004

    func load(latitude: Double, longitude: Double) async throws -> Neighborhood {
        async let all = count(latitude, longitude, where: "DOR_UC='001'")
        async let older = count(latitude, longitude, where: "DOR_UC='001' AND ACT_YR_BLT>0 AND ACT_YR_BLT<2002")
        return try await Neighborhood(homes: all, olderHomes: older)
    }

    private func count(_ lat: Double, _ lon: Double, where clause: String) async throws -> Int {
        var c = URLComponents(string: Self.layer)!
        c.queryItems = [
            .init(name: "geometry", value: "\(lon - Self.lonSpan),\(lat - Self.latSpan),\(lon + Self.lonSpan),\(lat + Self.latSpan)"),
            .init(name: "geometryType", value: "esriGeometryEnvelope"), .init(name: "inSR", value: "4326"),
            .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
            .init(name: "where", value: clause),
            // the statewide layer has some duplicate rows, so count distinct parcel IDs
            .init(name: "returnDistinctValues", value: "true"), .init(name: "outFields", value: "PARCEL_ID"),
            .init(name: "returnGeometry", value: "false"),
            .init(name: "returnCountOnly", value: "true"), .init(name: "f", value: "json"),
        ]
        let (data, _) = try await session.data(from: c.url!)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let n = json["count"] as? Int
        else { throw URLError(.badServerResponse) }
        return n
    }

    static func shareText(_ n: Neighborhood, street: String, perHome: Int) -> String {
        let pct = Int((n.olderShare * 100).rounded())
        return """
        Neighborhood wind-discount check (WindCredit)

        Within about a quarter mile of \(street), there are about \(n.homes) single-family homes. \(n.olderHomes) of them (\(pct)%) were built before Florida's 2002 building code, so many likely qualify for hurricane-insurance discounts they may not be getting.

        If just 1 in 4 is missing a discount the size of mine, that's about \(AppModel.money(n.dollarsIfQuarterMissing(perHome: perHome))) a year our neighborhood is overpaying.

        Florida law (Fla. Stat. 627.0629) requires insurers to offer these discounts. A wind-mitigation inspection is the first step, and My Safe Florida Home offers free ones. Could you help get the word out?

        Source: Florida statewide parcel data (Dept. of Revenue tax roll). Estimate only.
        """
    }
}
