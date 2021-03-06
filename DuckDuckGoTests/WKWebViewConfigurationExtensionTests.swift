//
//  WKWebViewConfigurationExtensionTests.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import WebKit

class WKWebViewConfigurationExtensionTests: XCTestCase {
    
    func testWhenWebViewCreatedWithNonPersistenceThenDataStoreIsNonPersistent() {
        let configuration = WKWebViewConfiguration.nonPersistent()
        let webView = WKWebView(frame: CGRect(), configuration: configuration)
        XCTAssertFalse(webView.configuration.websiteDataStore.isPersistent)
    }
    
    func testWhenWebViewCreatedWithPersistenceThenDataStoreIsPersistent() {
        let configuration = WKWebViewConfiguration.persistent()
        let webView = WKWebView(frame: CGRect(), configuration: configuration)
        XCTAssertTrue(webView.configuration.websiteDataStore.isPersistent)
    }
    
    func testWhenDddgNameForUserAgentRequestedThenNameAndVersionAreCorrect() {
        XCTAssertEqual("DuckDuckGo/7", WKWebViewConfiguration.ddgNameForUserAgent)
    }
    
    func testWhenPersistantConfigurationCreatedThenApplicationForUserAgentIsSet() {
        let configuration = WKWebViewConfiguration.persistent()
        XCTAssertTrue(configuration.applicationNameForUserAgent?.hasSuffix("DuckDuckGo/7") ?? false)
    }
    
    func testWhenNonPersistantConfigurationCreatedThenApplicationForUserAgentIsSet() {
        let configuration = WKWebViewConfiguration.nonPersistent()
        XCTAssertTrue(configuration.applicationNameForUserAgent?.hasSuffix("DuckDuckGo/7") ?? false)
    }
}
