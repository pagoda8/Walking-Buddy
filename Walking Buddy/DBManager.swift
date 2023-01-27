//
//  DBManager.swift
//  Walking Buddy
//
//  Created by Wojtek on 26/01/2023.
//
//	Manages database operations

import Foundation
import CloudKit

public class DBManager {
	
	//Reference for other classes
	public static let shared = DBManager()
	
	//Reference to the container
	private let container = CKContainer(identifier: "iCloud.Walking-Buddy")
	
	//Called once, when the shared variable is accessed
	private init() {}
	
	//Saves a record and returns true if successful
	public func saveRecord(record: CKRecord, completion: @escaping (Bool) -> Void) {
		container.publicCloudDatabase.save(record) { returnedRecord, returnedError in
			if ((returnedError?.localizedDescription) == nil) {
				completion(true)
			}
			else {
				completion(false)
			}
		}
	}
	
	//Returns an array of records that result from a query
	public func getRecords(query: CKQuery, completion: @escaping ([CKRecord]) -> Void) {
		let queryOperation = CKQueryOperation(query: query)
		var returnedRecords: [CKRecord] = []
		
		queryOperation.recordMatchedBlock = { returnedRecordID, returnedResult in
			switch returnedResult {
			case .success(let record):
				returnedRecords.append(record)
			case .failure(_):
				break
			}
		}
		
		queryOperation.queryResultBlock = { returnedResult in
			completion(returnedRecords)
		}
		
		addOperation(operation: queryOperation)
	}
	
	//Deletes a record and returns true if successful
	public func deleteRecord(record: CKRecord, completion: @escaping (Bool) -> Void) {
		container.publicCloudDatabase.delete(withRecordID: record.recordID) { returnedRecordID, returnedError in
			if ((returnedError?.localizedDescription) == nil) {
				completion(true)
			}
			else {
				completion(false)
			}
		}
	}
	
	//Adds an operation for the database
	private func addOperation(operation: CKDatabaseOperation) {
		container.publicCloudDatabase.add(operation)
	}
	
	//Enum for throwing errors
	public enum DBError: Error {
		case saveError
		case readError
	}
}
