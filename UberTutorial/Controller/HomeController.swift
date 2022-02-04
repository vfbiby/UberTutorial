//
//  HomeController.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/4.
//

import UIKit
import Firebase
import MapKit

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    let mapView = MKMapView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoginedInn()
//        signOut()
    }
    
    // MARK: - API
    
    func checkIfUserIsLoginedInn(){
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        } else {
            configureUI()
        }
    }
    
    func signOut(){
        do{
            try Auth.auth().signOut()
        } catch {
            print("DEBUG: Error signing out")
        }
    }
    // MARK: - Help Functions
    
    func configureUI(){
        view.addSubview(mapView)
        mapView.frame = view.frame
    }
}
