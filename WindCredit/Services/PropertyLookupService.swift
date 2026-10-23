import Foundation

// address → county geocoder (point) → parcel layer (parcel ID, use, homestead)
//         → Property Appraiser page (year built, roof)
struct PropertyLookupService {
    enum LookupError: LocalizedError {
        case notFound, network
        var errorDescription: String? {
            switch self {
            case .notFound: "We couldn’t find that address in Palm Beach County records. Check the house number and street (WindCredit only covers Palm Beach County for now)."
            case .network: "Couldn’t reach county records. Check your connection and try again."
            }
        }
    }

    var session: URLSession = .county

    private static let geocoder = "https://gis.pbcgov.org/arcgis/rest/services/Geocoder_New/Situs_115/GeocodeServer/findAddressCandidates"
    private static let parcels = "https://gis.pbcgov.org/arcgis/rest/services/Parcels/PARCEL_INFO/FeatureServer/4/query"
    private static let appraiser = "https://pbcpao.gov/Property/Details"

    func lookup(address: String) async throws -> PropertyRecord {
        let point = try await geocode(address)
        let parcel = try await parcel(at: point, houseNumber: Self.houseNumber(in: address))
        var record = PropertyRecord(
            parcelID: parcel.parid, address: point.matched, municipality: parcel.municipality,
            useDescription: parcel.use, yearBuilt: nil, roofCoverText: "", roofStructureText: "",
            livingArea: nil, marketValue: parcel.market, homestead: parcel.homestead, isCondo: parcel.isCondo,
            latitude: point.lat, longitude: point.lon)
        // roof details are a bonus; keep going without them
        if let details = try? await appraiserDetails(parcelID: parcel.parid) {
            record.merge(details)
        }
        return record
    }

    // MARK: Steps

    struct Point { let lat: Double; let lon: Double; let matched: String }

    func geocode(_ address: String) async throws -> Point {
        var c = URLComponents(string: Self.geocoder)!
        c.queryItems = [
            .init(name: "SingleLine", value: address), .init(name: "outFields", value: "Match_addr,Addr_type"),
            .init(name: "outSR", value: "4326"), .init(name: "maxLocations", value: "1"), .init(name: "f", value: "json"),
        ]
        let json = try await getJSON(c.url!)
        guard let cand = (json["candidates"] as? [[String: Any]])?.first,
              let score = cand["score"] as? Double, score >= 85,
              let loc = cand["location"] as? [String: Any],
              let x = loc["x"] as? Double, let y = loc["y"] as? Double
        else { throw LookupError.notFound }
        return Point(lat: y, lon: x, matched: (cand["address"] as? String) ?? address)
    }

    struct Parcel { let parid: String; let use: String; let isCondo: Bool; let homestead: Bool; let market: Int?; let municipality: String; let site: String }

    func parcel(at p: Point, houseNumber: String?) async throws -> Parcel {
        // Points on a lot line miss, so retry with a 25 m buffer and match the house number
        // (the buffer alone can grab the neighbor).
        for distance in [0, 25] {
            var c = URLComponents(string: Self.parcels)!
            var items: [URLQueryItem] = [
                .init(name: "geometry", value: "\(p.lon),\(p.lat)"), .init(name: "geometryType", value: "esriGeometryPoint"),
                .init(name: "inSR", value: "4326"),
                .init(name: "outFields", value: "PARID,SITE_ADDR_STR,PROPERTY_USE,CONDO,HMSTD_FLG,TOTAL_MARKET,MUNICIPALITY"),
                .init(name: "returnGeometry", value: "false"), .init(name: "f", value: "json"),
            ]
            if distance > 0 { items += [.init(name: "distance", value: "\(distance)"), .init(name: "units", value: "esriSRUnit_Meter")] }
            c.queryItems = items
            let json = try await getJSON(c.url!)
            let rows = ((json["features"] as? [[String: Any]]) ?? []).compactMap { $0["attributes"] as? [String: Any] }
            let parcels = rows.map(Self.parcel(from:))
            if let match = Self.pick(parcels, houseNumber: houseNumber) { return match }
        }
        throw LookupError.notFound
    }

    static func parcel(from a: [String: Any]) -> Parcel {
        Parcel(
            parid: a["PARID"] as? String ?? "",
            use: a["PROPERTY_USE"] as? String ?? "",
            isCondo: (a["CONDO"] as? String ?? "").uppercased() == "YES",
            homestead: (a["HMSTD_FLG"] as? String ?? "").uppercased().hasPrefix("Y"),
            market: (a["TOTAL_MARKET"] as? Double).map { Int($0) },
            municipality: a["MUNICIPALITY"] as? String ?? "",
            site: a["SITE_ADDR_STR"] as? String ?? "")
    }

    static func pick(_ parcels: [Parcel], houseNumber: String?) -> Parcel? {
        let valid = parcels.filter { !$0.parid.isEmpty }
        if let n = houseNumber, let m = valid.first(where: { $0.site.hasPrefix(n + " ") }) { return m }
        return valid.count == 1 ? valid.first : nil
    }

    static func houseNumber(in address: String) -> String? {
        let first = address.split(separator: " ").first.map(String.init) ?? ""
        return first.allSatisfy(\.isNumber) && !first.isEmpty ? first : nil
    }

    // MARK: Property Appraiser page

    struct AppraiserDetails: Equatable {
        var yearBuilt: Int?
        var roofCover: String
        var roofStructure: String
        var livingArea: Int?
        var homestead: Bool?
        var marketValue: Int?
        var useDescription: String?
    }

    func appraiserDetails(parcelID: String) async throws -> AppraiserDetails {
        var c = URLComponents(string: Self.appraiser)!
        c.queryItems = [.init(name: "parcelId", value: parcelID)]
        let (data, response) = try await session.data(from: c.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw LookupError.network }
        return try Self.parseAppraiserPage(String(decoding: data, as: UTF8.self))
    }

    // No official API, but the page embeds its data as `var model = {...};`.
    static func parseAppraiserPage(_ html: String) throws -> AppraiserDetails {
        guard let start = html.range(of: "var model = "),
              let end = html.range(of: "};", range: start.upperBound..<html.endIndex)
        else { throw LookupError.notFound }
        let jsonText = html[start.upperBound..<end.lowerBound] + "}"
        guard let model = try JSONSerialization.jsonObject(with: Data(jsonText.utf8)) as? [String: Any] else { throw LookupError.notFound }

        var elements: [String: String] = [:]
        let structural = model["structuralDetails"] as? [String: Any]
        for e in (structural?["StructuralElements"] as? [[String: Any]]) ?? [] {
            // multi-building parcels: just use building 1
            guard (e["BuildingNumber"] as? String ?? "1") == "1" else { continue }
            let name = (e["ElementName"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            elements[name] = (e["ElementValue"] as? String ?? "").trimmingCharacters(in: .whitespaces)
        }
        let exemptions = (model["exemptionInfo"] as? [[String: Any]]) ?? []
        let homestead = exemptions.contains { ($0["Description"] as? String ?? "").uppercased().contains("HOMESTEAD") }
        let appraisal = (model["appraisalInfo"] as? [[String: Any]])?.first
        let detail = model["propertyDetail"] as? [String: Any]

        return AppraiserDetails(
            yearBuilt: elements["Year Built"].flatMap { Int($0) },
            roofCover: elements["Roof Cover"] ?? "",
            roofStructure: elements["Roof Structure"] ?? "",
            livingArea: (elements["Area Under Air"] ?? elements["BAS  Base Area"]).flatMap { Int($0) },
            homestead: homestead,
            marketValue: (appraisal?["TotalMarketValue"] as? String).flatMap { Int($0) },
            useDescription: detail?["UseCodeDesc"] as? String)
    }

    private func getJSON(_ url: URL) async throws -> [String: Any] {
        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { throw LookupError.network }
            return json
        } catch let e as LookupError { throw e } catch { throw LookupError.network }
    }
}

extension PropertyRecord {
    mutating func merge(_ d: PropertyLookupService.AppraiserDetails) {
        yearBuilt = d.yearBuilt ?? yearBuilt
        roofCoverText = d.roofCover
        roofStructureText = d.roofStructure
        livingArea = d.livingArea ?? livingArea
        marketValue = d.marketValue ?? marketValue
        if let h = d.homestead { homestead = homestead || h }
        if let u = d.useDescription, !u.isEmpty { useDescription = u }
    }
}

extension URLSession {
    /// County GIS servers can be slow; don't leave someone staring at a spinner for a minute.
    static let county: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
}
