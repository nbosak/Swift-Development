//
//  Transaction+UI.swift
//  AppKit
//
//  Created by Nicholas Bosak on 10/11/16.
//

import Foundation
import ModelKit

extension Transaction {

    var showsReceipt: Bool {
        guard let status = self.status else { return false }

        switch status {
        case .approved, .requested:
            return true

        case .blocked, .declined, .reversed:
            return false

        }
    }

    var showsExpenseType: Bool {
        guard let status = self.status else { return false }

        switch status {
        case .approved, .requested:
            return true

        case .blocked, .declined, .reversed:
            return false

        }
    }
}

extension TransactionStatus {

    var displayColor: UIColor {

        switch self {
        case .blocked, .declined:
            return .red

        case .requested, .approved:
            return .gray

        case .reversed:
            return .green
        }
    }

    var displayIcon: UIImage? {
        switch self {
        case .approved:
            return UIImage(named: "check")?.withRenderingMode(.alwaysTemplate)

        case .blocked, .declined:
            return UIImage(named: "strike")?.withRenderingMode(.alwaysTemplate)

        case .requested:
            return UIImage(named: "hist_requested")?.withRenderingMode(.alwaysTemplate)

        case .reversed:
            return UIImage(named: "hist_reversal")?.withRenderingMode(.alwaysTemplate)

        }
    }
}
