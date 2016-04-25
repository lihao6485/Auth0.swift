// Requests.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Alamofire

public typealias CreateUser = (email: String, username: String?, verified: Bool)

public struct CreateUserRequest: Request {

    let request: Alamofire.Request

    public func start(callback: Result<CreateUser, Authentication.Error> -> ()) {
        request.responseJSON { response in
            switch response.result {
            case .Success(let payload):
                if let dictionary = payload as? [String: String], let email: String = dictionary["email"] {
                    let username = payload["username"] as? String
                    let verified = payload["email_verified"] as? Bool ?? false
                    callback(.Success(result: (email: email, username: username, verified: verified)))
                } else {
                    callback(.Failure(error: .InvalidResponse(response: payload)))
                }
            case .Failure(let cause):
                callback(.Failure(error: authenticationError(response, cause: cause)))
            }
        }
    }
}

public struct CredentialsRequest: Request {

    let request: Alamofire.Request

    public func start(callback: Result<Credentials, Authentication.Error> -> ()) {
        request.responseJSON { response in
            switch response.result {
            case .Success(let payload):
                if let dictionary = payload as? [String: String], let credentials = Credentials(dictionary: dictionary) {
                    callback(.Success(result: credentials))
                } else {
                    callback(.Failure(error: .InvalidResponse(response: payload)))
                }
            case .Failure(let cause):
                callback(.Failure(error: authenticationError(response, cause: cause)))
            }
        }
    }
}

public struct ResetPasswordRequest: Request {

    let request: Alamofire.Request

    public func start(callback: Result<Void, Authentication.Error> -> ()) {
        request.responseData { response in
            switch response.result {
            case .Success:
                callback(.Success(result: ()))
            case .Failure(let cause):
                callback(.Failure(error: authenticationError(response.data, cause: cause)))
            }
        }
    }
}

private func authenticationError(response: Alamofire.Response<AnyObject, NSError>, cause: NSError) -> Authentication.Error {
    if let jsonData = response.data {
        return authenticationError(jsonData, cause: cause)
    } else {
        return .Unknown(cause: cause)
    }
}

private func authenticationError(data: NSData?, cause: NSError) -> Authentication.Error {
    if
        let data = data,
        let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()),
        let payload = json as? [String: AnyObject] {
        return payloadError(payload, cause: cause)
    } else {
        return .Unknown(cause: cause)
    }
}

private func payloadError(payload: [String: AnyObject], cause: ErrorType) -> Authentication.Error {
    if let code = payload["error"] as? String, let description = payload["error_description"] as? String {
        return .Response(code: code, description: description)
    }

    if let code = payload["code"] as? String, let description = payload["description"] as? String {
        return .Response(code: code, description: description)
    }

    return .Unknown(cause: cause)
}
