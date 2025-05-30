import Foundation

class NMEASentenceParser {
    static let shared = NMEASentenceParser()

    private init() {}

    func parse(_ nmeaSentence: String) -> Any? {
        if nmeaSentence.isEmpty {
            return nil
        }
        if nmeaSentence.contains("GGA") {
            return GPGGA(nmeaSentence)
        } else if nmeaSentence.contains("GSA") {
            return GPGSA(nmeaSentence)
        } 
        else if nmeaSentence.contains("RMC") 
        {
            return GPRMC(nmeaSentence)
        }
        else if nmeaSentence.contains("GSV") {
            return GPGSV(nmeaSentence)
        }
        return nil
    }

    class NMEASentence {
        private var sentence: String
        var trimmedSentence: String

        var isValid: Bool {
            return sentence.suffix(2) == checksum().hexValue
        }

        func checksum() -> UInt8 {
            var xor: UInt8 = 0
            for index in 0..<trimmedSentence.utf8.count {
                xor = xor ^ Array(trimmedSentence.utf8)[index]
            }
            return xor
        }

        init?(_ nmeaSentence: String) {
            sentence = nmeaSentence

            // duplicate sentence trimmed from its "$" and checksum
            let start = sentence.index(sentence.startIndex, offsetBy: 1)
            let end = sentence.index(sentence.endIndex, offsetBy: -3)
            trimmedSentence = String(sentence[start..<end])

            if !isValid {
                return nil
            }
        }
    }

    class GPGGA: NMEASentence {
        override init?(_ nmeaSentence: String) {
            super.init(nmeaSentence)

            let splittedSentence = trimmedSentence.split(
                separator: ",",
                maxSplits: Int.max,
                omittingEmptySubsequences: false
            )

            utcTime = Float(splittedSentence[1])
            latitude = Coordinate(splittedSentence[2], splittedSentence[3])
            longitude = Coordinate(splittedSentence[4], splittedSentence[5])
            fixQuality = FixQuality(rawValue: Int(splittedSentence[6]) ?? -1)
            numberOfSatellites = Int(splittedSentence[7])
            horizontalDilutionOfPosition = Float(splittedSentence[8])
            mslAltitude = Float(splittedSentence[9])
            mslAltitudeUnit = String(splittedSentence[10])
            heightOfGeoid = Float(splittedSentence[11])
            heightOfGeoidUnit = String(splittedSentence[12])

            if [utcTime, latitude, longitude, fixQuality,
                numberOfSatellites, horizontalDilutionOfPosition, mslAltitude, mslAltitudeUnit,
                heightOfGeoid, heightOfGeoidUnit].atleastOneIsNil() {
               // return nil
            }
        }

        var utcTime: Float?
        var latitude: Coordinate?
        var longitude: Coordinate?
        var fixQuality: FixQuality?
        var numberOfSatellites: Int?
        var horizontalDilutionOfPosition: Float?
        var mslAltitude: Float?
        var mslAltitudeUnit: String?
        var heightOfGeoid: Float?
        var heightOfGeoidUnit: String?
    }

    class GPGSA: NMEASentence {
        override init?(_ nmeaSentence: String) {
            super.init(nmeaSentence)

            let splittedSentence = trimmedSentence.split(
                separator: ",",
                maxSplits: Int.max,
                omittingEmptySubsequences: false
            )

            fixSelectionMode = FixSelectionMode(rawValue: Character(String(splittedSentence[1])))
            threeDFixMode = FixMode(rawValue: Int(splittedSentence[2]) ?? 0)
            for index in 0..<12 {
                prn.append(Int(splittedSentence[3 + index]))
            }
            pdop = Float(splittedSentence[15])
            hdop = Float(splittedSentence[16])
            vdop = Float(splittedSentence[17])

            if [fixSelectionMode, threeDFixMode, hdop, vdop, pdop].atleastOneIsNil() {
               // return nil
            }
        }

        var fixSelectionMode: FixSelectionMode?
        var threeDFixMode: FixMode?
        var prn = [Int?]()
        var pdop: Float?
        var hdop: Float?
        var vdop: Float?
    }

    class GPGSV: NMEASentence {
        override init?(_ nmeaSentence: String) {
            super.init(nmeaSentence)

            let splittedSentence = trimmedSentence.split(
                separator: ",",
                maxSplits: Int.max,
                omittingEmptySubsequences: false
            )

            // Add appropriate parsing for GPGSV sentence
            numberOfSatellitesInView = Int(splittedSentence[2])


            if [].atleastOneIsNil() {
                return nil
            }
        }
        
        var numberOfSatellitesInView: Int?

    }

    class GPRMC: NMEASentence {
        override init?(_ nmeaSentence: String) {
            super.init(nmeaSentence)

            let splittedSentence = trimmedSentence.split(
                separator: ",",
                maxSplits: Int.max,
                omittingEmptySubsequences: false
            )

            guard splittedSentence.count > 11 else {
                return nil
            }

            time = String(splittedSentence[1])
            status = Character(String(splittedSentence[2]))
            latitude = parseCoordinate(String(splittedSentence[3]), direction: String(String(splittedSentence[4])))
            longitude = parseCoordinate(String(splittedSentence[5]), direction: String(String(splittedSentence[6])))
            speedOverGround = Float(splittedSentence[7])
            courseOverGround = Float(splittedSentence[8])
            date = String(splittedSentence[9])

            if [time, status, latitude, longitude, speedOverGround, courseOverGround, date].atleastOneIsNil() {
               // return nil
            }
        }

        var time: String?
        var status: Character?
        var latitude: Double?
        var longitude: Double?
        var speedOverGround: Float?
        var courseOverGround: Float?
        var date: String?


    }

    struct Coordinate {
        var coordinate: Float?
        var direction: Direction?

        init?(_ coordinate: Substring, _ direction: Substring) {
            self.coordinate =
            Float(parseCoordinate(String(coordinate),direction: String(direction))?.description ?? "0.0")
            //Float(coordinate) "ˀ
             self.direction = Direction(String(direction))

            guard self.coordinate != nil, self.direction != nil else {
                return nil
            }
        }
    }

    enum FixSelectionMode: Character {
        case manual = "M"
        case auto = "A"
    }

    enum FixMode: Int {
        case nofix = 1
        case twod = 2
        case threed = 3
    }

    enum Direction: Character {
        case north = "N"
        case south = "S"
        case east = "E"
        case west = "W"

        init?(_ direction: String) {
            switch String(direction) {
            case "N":
                self = .north
            case "S":
                self = .south
            case "E":
                self = .east
            case "W":
                self = .west
            default:
                return nil
            }
        }
    }

    enum FixQuality: Int {
        case invalid = 0
        case gpsFixSPS = 1
        case dGPSFix = 2
        case ppsFix = 3
        case realTimeKinematic = 4
        case floatRTK = 5
        case estimated = 6
        case manualInputMode = 7
        case simulationMode = 8
    }
}

// Helper extension for nil checks
extension Collection where Element == Any? {
    func allNotNil() -> Bool {
        return self.compactMap { $0 }.count > self.count
    }

    func atleastOneNotNil() -> Bool {
        return self.compactMap { $0 }.count > 0
    }

    func allNil() -> Bool {
        return self.compactMap { $0 }.count == 0
    }

    func atleastOneIsNil() -> Bool {
        return self.contains { $0 == nil }
    }
}

// Extension for checksum validation
extension UInt8 {
    var hexValue: String {
        return (self < 16 ? "0" : "") + String(self, radix: 16, uppercase: true)
    }
}



private func parseCoordinate(_ value: String, direction: String) -> Double? {
    guard !value.isEmpty else { return nil }

    let degrees = Double(value.prefix(2)) ?? 0
    let minutes = Double(value.suffix(value.count - 2)) ?? 0

    var coordinate = degrees + (minutes / 60)

    if direction == "S" || direction == "W" {
        coordinate = -coordinate
    }

    return coordinate
}
