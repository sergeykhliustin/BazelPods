//
//  ViewController.swift
//  TestApp
//
//  Created by Sergey Khliustin on 20.07.2022.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Run succeeded!"
        label.textColor = .black
        view.addSubview(label)
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0)
        ])
    }
}

