import CloudKit
import CryptoKit
import Foundation

nonisolated struct FriendRankingEntry: Identifiable, Sendable, Equatable {
    let userRecordName: String
    let displayName: String
    let distanceMeters: Double
    let isCurrentUser: Bool
    let rank: Int

    var id: String {
        userRecordName
    }
}

nonisolated struct FriendInvitation: Sendable, Equatable {
    let friendID: String
    let qrURL: URL
}

nonisolated enum ICloudSetupStatus: Sendable, Equatable {
    case idle
    case checking
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
}

actor CloudFriendsService {
    enum ServiceError: Error {
        case iCloudUnavailable
        case invalidInvitation
        case cannotAddSelf
    }

    private enum RecordType {
        static let profile = "DriveLogProfile"
        static let friendship = "DriveLogFriendship"
        static let monthlyDistance = "DriveLogMonthlyDistance"
    }

    private let containerProvider: () -> CKContainer
    private let defaults: UserDefaults

    init(
        containerProvider: @escaping () -> CKContainer = { .default() },
        defaults: UserDefaults = .standard
    ) {
        self.containerProvider = containerProvider
        self.defaults = defaults
    }

    private var container: CKContainer {
        containerProvider()
    }

    private var database: CKDatabase {
        container.publicCloudDatabase
    }

    func setupStatus() async -> ICloudSetupStatus {
        do {
            return switch try await container.accountStatus() {
            case .available:
                .available
            case .noAccount:
                .noAccount
            case .restricted:
                .restricted
            case .couldNotDetermine, .temporarilyUnavailable:
                .temporarilyUnavailable
            @unknown default:
                .temporarilyUnavailable
            }
        } catch {
            return .temporarilyUnavailable
        }
    }

    @discardableResult
    func bootstrap(displayName: String) async throws -> String {
        guard await setupStatus() == .available else {
            throw ServiceError.iCloudUnavailable
        }
        let ownerRecordName = try await container.userRecordID().recordName
        let profileID = CKRecord.ID(recordName: profileRecordName(ownerRecordName))
        let record = try await recordIfPresent(id: profileID)
            ?? CKRecord(recordType: RecordType.profile, recordID: profileID)
        record["ownerRecordName"] = ownerRecordName as CKRecordValue
        record["displayName"] = normalizedDisplayName(displayName) as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await database.save(record)
        return ownerRecordName
    }

    func invitation(displayName: String) async throws -> FriendInvitation {
        let ownerRecordName = try await bootstrap(displayName: displayName)
        let friendID = try await ensureFriendID(
            ownerRecordName: ownerRecordName,
            displayName: displayName
        )
        var components = URLComponents()
        components.scheme = "drivelog"
        components.host = "friend"
        components.queryItems = [URLQueryItem(name: "id", value: friendID)]
        guard let url = components.url else {
            throw ServiceError.invalidInvitation
        }
        return FriendInvitation(friendID: friendID, qrURL: url)
    }

    func acceptInvitation(_ url: URL, displayName: String) async throws {
        guard url.scheme?.lowercased() == "drivelog",
              url.host?.lowercased() == "friend"
        else { throw ServiceError.invalidInvitation }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        if let friendID = queryItems?.first(where: { $0.name == "id" })?.value {
            try await acceptFriendID(friendID, displayName: displayName)
            return
        }
        // Keep previously issued QR codes usable after switching to public friend IDs.
        guard let invitedUser = queryItems?.first(where: { $0.name == "user" })?.value,
              !invitedUser.isEmpty
        else { throw ServiceError.invalidInvitation }
        try await addFriend(ownerRecordName: invitedUser, displayName: displayName)
    }

    func acceptFriendID(_ friendID: String, displayName: String) async throws {
        let normalizedID = try normalizedFriendID(friendID)
        let aliasID = CKRecord.ID(recordName: friendAliasRecordName(normalizedID))
        guard let alias = try await recordIfPresent(id: aliasID),
              let invitedUser = alias["ownerRecordName"] as? String,
              !invitedUser.isEmpty
        else { throw ServiceError.invalidInvitation }
        try await addFriend(ownerRecordName: invitedUser, displayName: displayName)
    }

    private func addFriend(ownerRecordName invitedUser: String, displayName: String) async throws {
        let ownUser = try await bootstrap(displayName: displayName)
        guard ownUser != invitedUser else { throw ServiceError.cannotAddSelf }
        guard try await profile(ownerRecordName: invitedUser) != nil else {
            throw ServiceError.invalidInvitation
        }
        let participants = [ownUser, invitedUser].sorted()
        let recordID = CKRecord.ID(recordName: "friendship_" + hash(
            participants.joined(separator: "|")
        ))
        let record = try await recordIfPresent(id: recordID)
            ?? CKRecord(recordType: RecordType.friendship, recordID: recordID)
        record["participants"] = participants as CKRecordValue
        record["createdAt"] = (record["createdAt"] as? Date ?? Date()) as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await database.save(record)
        storeLocalFriend(invitedUser, currentUser: ownUser)
    }

    private func ensureFriendID(
        ownerRecordName: String,
        displayName: String
    ) async throws -> String {
        let digest = hash(ownerRecordName).uppercased()
        for offset in stride(from: 0, through: 48, by: 12) {
            let start = digest.index(digest.startIndex, offsetBy: offset)
            let end = digest.index(start, offsetBy: 12)
            let rawID = String(digest[start ..< end])
            let recordID = CKRecord.ID(recordName: friendAliasRecordName(rawID))
            if let existing = try await recordIfPresent(id: recordID) {
                if existing["ownerRecordName"] as? String == ownerRecordName {
                    return formattedFriendID(rawID)
                }
                continue
            }
            let alias = CKRecord(recordType: RecordType.profile, recordID: recordID)
            alias["ownerRecordName"] = ownerRecordName as CKRecordValue
            alias["displayName"] = normalizedDisplayName(displayName) as CKRecordValue
            alias["updatedAt"] = Date() as CKRecordValue
            do {
                _ = try await database.save(alias)
                return formattedFriendID(rawID)
            } catch let error as CKError where error.code == .serverRecordChanged {
                if let existing = try await recordIfPresent(id: recordID),
                   existing["ownerRecordName"] as? String == ownerRecordName
                {
                    return formattedFriendID(rawID)
                }
            }
        }
        throw ServiceError.invalidInvitation
    }

    func rankings(
        month: LocalMonth,
        ownDistanceMeters: Double,
        displayName: String
    ) async throws -> [FriendRankingEntry] {
        let ownUser = try await bootstrap(displayName: displayName)
        try await saveMonthlyDistance(
            ownerRecordName: ownUser,
            month: month,
            distanceMeters: ownDistanceMeters
        )
        var friendIDs = Set(localFriends(currentUser: ownUser))
        if let cloudFriendIDs = try? await cloudFriends(currentUser: ownUser) {
            friendIDs.formUnion(cloudFriendIDs)
        }
        friendIDs.remove(ownUser)
        var values: [(String, String, Double, Bool)] = [
            (ownUser, normalizedDisplayName(displayName), max(0, ownDistanceMeters), true)
        ]
        for friendID in friendIDs.sorted() {
            guard let profile = try? await profile(ownerRecordName: friendID) else {
                continue
            }
            let name = profile["displayName"] as? String ?? "友達"
            let distance = try? await monthlyDistance(
                ownerRecordName: friendID,
                month: month
            )
            values.append((friendID, name, max(0, distance ?? 0), false))
        }
        let sorted = values.sorted { first, second in
            if first.2 == second.2 {
                if first.3 != second.3 { return first.3 }
                return first.1 < second.1
            }
            return first.2 > second.2
        }
        return sorted.enumerated().map { index, value in
            FriendRankingEntry(
                userRecordName: value.0,
                displayName: value.1,
                distanceMeters: value.2,
                isCurrentUser: value.3,
                rank: index + 1
            )
        }
    }

    private func saveMonthlyDistance(
        ownerRecordName: String,
        month: LocalMonth,
        distanceMeters: Double
    ) async throws {
        let monthKey = monthKey(month)
        let recordID = CKRecord.ID(recordName: monthlyRecordName(
            ownerRecordName: ownerRecordName,
            monthKey: monthKey
        ))
        let record = try await recordIfPresent(id: recordID)
            ?? CKRecord(recordType: RecordType.monthlyDistance, recordID: recordID)
        record["ownerRecordName"] = ownerRecordName as CKRecordValue
        record["monthKey"] = monthKey as CKRecordValue
        record["distanceMeters"] = max(0, distanceMeters) as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        _ = try await database.save(record)
    }

    private func monthlyDistance(
        ownerRecordName: String,
        month: LocalMonth
    ) async throws -> Double {
        let recordID = CKRecord.ID(recordName: monthlyRecordName(
            ownerRecordName: ownerRecordName,
            monthKey: monthKey(month)
        ))
        return try await recordIfPresent(id: recordID)?["distanceMeters"] as? Double ?? 0
    }

    private func profile(ownerRecordName: String) async throws -> CKRecord? {
        try await recordIfPresent(id: CKRecord.ID(
            recordName: profileRecordName(ownerRecordName)
        ))
    }

    private func cloudFriends(currentUser: String) async throws -> [String] {
        let predicate = NSPredicate(format: "participants CONTAINS %@", currentUser)
        let query = CKQuery(recordType: RecordType.friendship, predicate: predicate)
        let records = try await records(matching: query)
        return records.flatMap { record in
            (record["participants"] as? [String] ?? []).filter { $0 != currentUser }
        }
    }

    private func records(matching query: CKQuery) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKQueryOperation(query: query)
            let resultLock = NSLock()
            var values: [CKRecord] = []
            operation.recordMatchedBlock = { _, result in
                guard case let .success(record) = result else { return }
                resultLock.lock()
                values.append(record)
                resultLock.unlock()
            }
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    resultLock.lock()
                    let records = values
                    resultLock.unlock()
                    continuation.resume(returning: records)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    private func recordIfPresent(id: CKRecord.ID) async throws -> CKRecord? {
        do {
            return try await database.record(for: id)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    private func localFriends(currentUser: String) -> [String] {
        defaults.stringArray(forKey: localFriendsKey(currentUser)) ?? []
    }

    private func storeLocalFriend(_ friend: String, currentUser: String) {
        var values = Set(localFriends(currentUser: currentUser))
        values.insert(friend)
        defaults.set(values.sorted(), forKey: localFriendsKey(currentUser))
    }

    private func localFriendsKey(_ currentUser: String) -> String {
        "cloudkit.friends." + hash(currentUser)
    }

    private func profileRecordName(_ ownerRecordName: String) -> String {
        "profile_" + hash(ownerRecordName)
    }

    private func friendAliasRecordName(_ normalizedFriendID: String) -> String {
        "friend_id_" + normalizedFriendID
    }

    private func normalizedFriendID(_ value: String) throws -> String {
        let compact = value.uppercased().filter { !$0.isWhitespace && $0 != "-" }
        let allowed = CharacterSet(charactersIn: "0123456789ABCDEF")
        guard compact.count == 12,
              compact.unicodeScalars.allSatisfy(allowed.contains)
        else { throw ServiceError.invalidInvitation }
        return compact
    }

    private func formattedFriendID(_ value: String) -> String {
        let normalized = value.uppercased()
        let firstEnd = normalized.index(normalized.startIndex, offsetBy: 4)
        let secondEnd = normalized.index(firstEnd, offsetBy: 4)
        return [
            String(normalized[..<firstEnd]),
            String(normalized[firstEnd ..< secondEnd]),
            String(normalized[secondEnd...])
        ].joined(separator: "-")
    }

    private func monthlyRecordName(ownerRecordName: String, monthKey: String) -> String {
        "month_" + hash(ownerRecordName + "|" + monthKey)
    }

    private func monthKey(_ month: LocalMonth) -> String {
        String(format: "%04d-%02d", month.year, month.month)
    }

    private func normalizedDisplayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ドライバー" : String(trimmed.prefix(30))
    }

    private func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map {
            String(format: "%02x", $0)
        }.joined()
    }
}
