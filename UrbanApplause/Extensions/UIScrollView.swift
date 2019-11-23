//
//  UIScrollView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-31.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {

    func scrollViewAvoidKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    @objc func keyboardWillShow(notification: Notification) {
        guard let endFrame = notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.contentInset.bottom = endFrame.height
    }
    @objc func keyboardWillHide(notification: Notification) {
        self.contentInset.bottom = 0
    }
}
