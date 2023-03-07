//
//  SettingsViewController.swift
//  BreakfastFinder
//
//  Created by Dhruv Mathur on 2023-03-06.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

public var settingsMap2: [String : Int] =
["bottleSound"  : 1,
 "personSound"  : 1,
 "tableSound"   : 1,
 "chairSound"   : 1,
 "bedSound"     : 1,
 "defaultSound" : 1,
 "distanceScale" : 0,
 "enableVoiceOver" : 1,
 "enableLocation" : 1,
 "volume" : 100
]

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var enableVoiceOverSwitch: UISwitch!
    @IBOutlet weak var enableLocationHistorySwitch: UISwitch!
        
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    
    @IBOutlet weak var objectDistanceScaleTextField: UITextField!
    @IBOutlet weak var defaultSoundTextField: UITextField!
    @IBOutlet weak var bottleSoundTextField: UITextField!
    @IBOutlet weak var personSoundTextField: UITextField!
    @IBOutlet weak var tableSoundTextField: UITextField!
    @IBOutlet weak var bedSoundTextField: UITextField!
    @IBOutlet weak var chairSoundTextField: UITextField!
    
    
    @IBAction func saveChangesButton(_ sender: Any) {
        
        if let objectDistanceScaleText = objectDistanceScaleTextField.text {
            if objectDistanceScaleTextField.text != "" {
                settingsMap2["distanceScale"] = Int(objectDistanceScaleText)
            }
        }
        
        if let defaultSoundText = defaultSoundTextField.text {
            if defaultSoundTextField.text != "" {
                settingsMap2["defaultSound"] = Int(defaultSoundText)
            }
        }
        
        if let bottleSoundText = bottleSoundTextField.text {
            if bottleSoundTextField.text != "" {
                settingsMap2["bottleSound"] = Int(bottleSoundText)
            }
        }
        
        if let personSoundText = personSoundTextField.text {
            if personSoundTextField.text != "" {
                settingsMap2["personSound"] = Int(personSoundText)
            }
        }
        
        if let tableSoundText = tableSoundTextField.text {
            if tableSoundTextField.text != "" {
                settingsMap2["tableSound"] = Int(tableSoundText)
            }
        }
        
        if let bedSoundText = bedSoundTextField.text {
            if bedSoundTextField.text != "" {
                settingsMap2["bedSound"] = Int(bedSoundText)
            }
        }
        
        if let chairSoundText = chairSoundTextField.text {
            if chairSoundTextField.text != "" {
                settingsMap2["chairSound"] = Int(chairSoundText)
            }
        }
                
        settingsMap2["volume"] = Int(volumeSlider.value)
        volumeLabel.text = String(settingsMap2["volume"]!)
        
        settingsMap2["enableVoiceOver"] = enableVoiceOverSwitch.isOn ? 1 : 0
        settingsMap2["enableLocation"] = enableLocationHistorySwitch.isOn ? 1 : 0
        
        for (k, val2) in settingsMap2 {
            print("\(k) : \(val2)")
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        for textField in self.view.subviews where textField is UITextField {
            textField.resignFirstResponder()
        }
        return true
    }

    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
        
        volumeLabel.text = String(settingsMap2["volume"]!)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
