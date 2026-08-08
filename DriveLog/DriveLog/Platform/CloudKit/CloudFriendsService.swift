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

    func invitationURL(displayName: String) async throws -> URL {
        let ownerRecordName = try await bootstrap(displayName: displayName)
        var components = URLComponents()
        components.scheme = "drivelog"
        components.host = "friend"
        components.queryItems = [URLQueryItem(name: "user", value: ownerRecordName)]
        guard let url = components.url else {
            throw ServiceError.invalidInvitation
        }
        return url
    }

    func acceptInvitation(_ url: URL, displayName: String) async throws {
        guard url.scheme?.lowercased() == "drivelog",
              url.host?.lowercased() == "friend",
              let invitedUser = URLComponents(url: url, resolvingAgainstBaseURL: false)?
              .queryItems?.first(where: { $0.name == "user" })?.value,
              !invitedUser.isEmpty
        else { throw ServiceError.invalidInvitation }
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
