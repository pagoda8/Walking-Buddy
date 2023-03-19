//
//  OpenAICaller.swift
//  Walking Buddy
//
//  Created by Wojtek on 19/03/2023.
//
//	Manages calls to the OpenAI API
//	API used: https://openai.com/blog/openai-api
//	Wrapper library used: https://github.com/adamrushy/OpenAISwift

import Foundation
import OpenAISwift

final class OpenAICaller {
	
	//Reference for other classes
	static let shared = OpenAICaller()
	
	//Wrapper library client
	private var client: OpenAISwift?
	
	@frozen enum Constants {
		static let key = "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"
	}
	
	private init() {}
	
	//Set up the client
	public func setup() {
		self.client = OpenAISwift(authToken: Constants.key)
	}
	
	//Returns the received response based on the input
	public func getResponse(input: String, completion: @escaping (Result<String, Error>) -> Void) {
		client?.sendCompletion(with: input, maxTokens: 300, completionHandler: { result in
			switch result {
			case .success(let model):
				let output = model.choices.first?.text ?? ""
				completion(.success(output))
			case .failure(let error):
				completion(.failure(error))
			}
		})
	}
}
