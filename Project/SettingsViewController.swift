//
//  SettingsViewController.swift
//  Project
//
//  Created by Dorian Bizgan on 7/8/20.
//  Copyright © 2020 Dorian Bizgan. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var voiceCategoryControl: UISegmentedControl!
    @IBOutlet weak var voiceGenderControl: UISegmentedControl!
    @IBOutlet weak var speedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        
        print(defaults.integer(forKey: "voiceCategoryPreference"))
        print(defaults.integer(forKey: "voiceGenderPreference"))
        
        let voiceCategoryPreference = defaults.integer(forKey: "voiceCategoryPreference")
        let voiceGenderPreference = defaults.integer(forKey: "voiceGenderPreference")

        voiceCategoryControl.selectedSegmentIndex = voiceCategoryPreference
        voiceGenderControl.selectedSegmentIndex = voiceGenderPreference

    }
    override func viewWillDisappear(_ animated: Bool) {
        let category = voiceCategoryControl.selectedSegmentIndex
        let gender = voiceGenderControl.selectedSegmentIndex

        let defaults = UserDefaults.standard
        
        // set user voice defaults
        defaults.set(category, forKey: "voiceCategoryPreference")
        defaults.set(gender, forKey: "voiceGenderPreference")
    }

}
