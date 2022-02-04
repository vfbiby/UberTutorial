//
//  HomeController.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/4.
//

import UIKit
import Firebase

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoginedInn()
        view.backgroundColor = .red
    }
    
    // MARK: - API
    
    func checkIfUserIsLoginedInn(){
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        } else {
            print("DEBUG: User id is \(String(describing: Auth.auth().currentUser?.uid))")
        }
    }
    
    func signOut(){
        do{
            try Auth.auth().signOut()
        } catch {
            print("DEBUG: Error signing out")
        }
    }
}
