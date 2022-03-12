//
//  HomeTests.swift
//  TDDCommerceTests
//
//  Created by Ahmed Ramy on 12/03/2022.
//

import XCTest
import Quick
import Nimble
@testable import TDDCommerce

class HomeTests: QuickSpec {
    override func spec() {
        describe("home page") {
            let sut = HomeViewModel()
            context("previewing") {
                context("when items are present") {
                    let expectedModels = [Item].stubbed()
                    network.expectedModel = expectedModels
                    it("displays the items to the user") {
                        sut.fetchItems()
                        expect(sut.state).to(be(.loaded(expectedModels)))
                    }
                }
            }
        }
    }
}
