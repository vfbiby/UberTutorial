//
//  Service.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/5.
//

import Firebase
import CoreLocation
import GeoFire

private let DB_REF = Database.database(url: "https://ubertutorial-5d8ef-default-rtdb.asia-southeast1.firebasedatabase.app/").reference()
let REF_USER = DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")

struct Service{
    static let shared = Service()
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void){
        REF_USER.child(uid).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let uid = snapshot.key
            let user = User(uid: uid, dictionary: dictionary)
            completion(user)
        }
    }
    
    func fetchDrivers(location: CLLocation, completion: @escaping(User) -> Void){
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        REF_DRIVER_LOCATIONS.observe(.value) { snapshot in
            geofire.query(at: location, withRadius: 0.5).observe(.keyEntered, with: { (uid, location) in
                self.fetchUserData(uid: uid) { user in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }
    }
}