import AMSMB2

class SMBClient {
    let serverURL: URL
    let credential: URLCredential
    let share: String
    
    lazy private var client = SMB2Manager(url: self.serverURL, credential: self.credential)!
    
    init(url: String, share: String, user: String, password: String) {
        serverURL = URL(string: url)!
        self.share = share
        credential = URLCredential(user: user, password: password, persistence: .forSession)
    }
    
    private func connect() async throws -> SMB2Manager {
        try await client.connectShare(name: self.share)
        return self.client
    }
    
    func listDirectory(path: String) async throws -> [String] {
        let client = try await connect()
        let files = try await client.contentsOfDirectory(atPath: path)
        return files.compactMap { entry -> String? in
            guard let rawName = entry[.pathKey] as? String else { return nil }
            let fileType = entry[.fileResourceTypeKey] as? URLFileResourceType
            let suffix = fileType == .directory ? "/" : ""
            return serverURL.absoluteString + "/" + rawName + suffix
        }
    }
    
    func downloadFile(atPath: String, to: String) async throws -> String {
        let client = try await connect()
        try await client.downloadItem(atPath: atPath, to: URL(fileURLWithPath: to))
        return to
    }
}
