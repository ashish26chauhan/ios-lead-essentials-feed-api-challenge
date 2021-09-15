//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { result in
			switch result {
			case let .success((data, response)):
				do {
					let items = try FeedImageMapper.map(data: data, response: response)
					completion(.success(items))
				} catch {
					completion(.failure(RemoteFeedLoader.Error.invalidData))
				}
			case .failure(_):
				completion(.failure(RemoteFeedLoader.Error.connectivity))
			}
		}
	}
}

private class FeedImageMapper {
	private struct Root: Decodable {
		let items: [Item]
	}

	private struct Item: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		var item: FeedImage {
			return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
		}
	}

	class func map(data: Data, response: HTTPURLResponse) throws -> [FeedImage] {
		guard response.statusCode == 200 else {
			throw RemoteFeedLoader.Error.invalidData
		}

		let root = try JSONDecoder().decode(Root.self, from: data)

		return root.items.map { $0.item }
	}
}
