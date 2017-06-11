//
//  PathComponent.swift
//  Nevertheless
//
//  Created by Ben Gottlieb on 6/10/17.
//  Copyright © 2017 Ben Gottlieb. All rights reserved.
//

import Foundation

public struct Path {
	public let path: URL
	
	public static var documents: Path = { Path(path: NSSearchPathForDirectoriesInDomains(.documentDirectory, [.userDomainMask], true).first!) }()
	public static var library: Path = { Path(path: NSSearchPathForDirectoriesInDomains(.libraryDirectory, [.userDomainMask], true).first!) }()
	public static var caches: Path = { Path(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true).first!) }()
	
	public init(path: String) {
		self.path = URL(fileURLWithPath: path)
	}
	
	public init(parent: Path, component: String) {
		self.path = parent.path.appendingPathComponent(component)
	}
	
	public subscript(_ name: String) -> Path {
		return Path(parent: self, component: name)
	}
	
	public subscript(_ name: String) -> Data? {
		get {
			let fileURL = self.path.appendingPathComponent(name)
			return try? Data(contentsOf: fileURL)
		}
		set {
			let fileURL = self.path.appendingPathComponent(name)
			try? newValue?.write(to: fileURL)
		}
	}
	
	public subscript<Type: Decodable>(_ name: String) -> Type? {
		get {
			guard let data: Data = self[name] else { return nil }
			
			let decoder = JSONDecoder()
			
			return try? decoder.decode(Type.self, from: data)
		}
		set {
			let encoder = JSONEncoder()
			if let data = try? encoder.encode(newValue) {
				self[name] = data
			}
		}
	}
	
}
