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
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoginedInn()
        enableLocationService()
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

extension HomeController: CLLocationManagerDelegate {
    func enableLocationService(){
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            print("DEBUG: Not determined...")
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth alawys...")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Auth when in use...")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        if status == .authorizedWhenInUse{
            locationManager.requestAlwaysAuthorization()
        }
    }
    
}
