//
//  UITextArea.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class UATextArea: UITextView, UITextViewDelegate {
    var placeholder: String?
    var placeholderTextColor: UIColor = UIColor.lightGray
    var defaultTextColor: UIColor = TypographyStyle.body.color
    
    init(placeholder: String?, value: String?) {
        self.placeholder = placeholder
        super.init(frame: .zero, textContainer: nil)
        translatesAutoresizingMaskIntoConstraints = false
        self.delegate = self
        self.font = TypographyStyle.body.font

        if let val = value, val.count > 0 {
            text = val
            textColor = defaultTextColor
        } else {
            text = placeholder
            textColor = placeholderTextColor
        }
        self.inputAccessoryView = toolbar
    }
    
    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        toolbar.barStyle = UIBarStyle.default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: Strings.DoneButtonTitle, style: .plain, target: self, action: #selector(dismissKeyboard(_:)))]
            toolbar.sizeToFit()
        return toolbar
    }()
    
    @objc func dismissKeyboard(_: Any) {
        self.resignFirstResponder()
    }
    
    func clearText() {
        self.text = placeholder
        self.textColor = placeholderTextColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func becomeFirstResponder() -> Bool {
        let doBecome = super.becomeFirstResponder()
        if doBecome, textColor == placeholderTextColor {
            self.selectedTextRange = self.textRange(from: self.beginningOfDocument, to: self.beginningOfDocument)
        }
        return doBecome
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText: String = self.text
        guard let nsRange = self.selectedRange else { return false }
        let updatedText = (currentText as NSString).replacingCharacters(in: nsRange, with: text)

        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {

            self.text = placeholder
            self.textColor = placeholderTextColor

            self.selectedTextRange = self.textRange(from: self.beginningOfDocument, to: self.beginningOfDocument)
        }

        // Else if the text view's placeholder is showing and the
        // length of the replacement string is greater than 0, set
        // the text color to default then set its text to the
        // replacement string
         else if self.textColor == placeholderTextColor && !text.isEmpty {
            self.textColor = defaultTextColor
            self.text = text
        }

        // For every other case, the text should change with the usual
        // behavior...
        else {
            return true
        }

        // ...otherwise return false since the updates have already
        // been made
        return false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.textColor == placeholderTextColor {
            self.selectedTextRange = textView.textRange(from: self.beginningOfDocument, to: self.beginningOfDocument)
        }
    }
}
