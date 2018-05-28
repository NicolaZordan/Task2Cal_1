//
//  SecondViewController.swift
//  Task2Cal
//
//  Created by Nicola Zordan on 12/5/16.
//  Copyright © 2016 CrosaraZordan. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    //UiTextFiledDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // keyboard go away
        textField.resignFirstResponder()
        return true
    }// called when 'return' key pressed. return NO to ignore.

    
    
}

