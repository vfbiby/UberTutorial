//
//  Service.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/5.
//

import Firebase

private let DB_REF = Database.database(url: "https://ubertutorial-5d8ef-default-rtdb.asia-southeast1.firebasedatabase.app/").reference()
let REF_USER = DB_REF.child("users")

struct Service{
    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid
    
    func fetchUserData(completion: @escaping(User) -> Void){
        REF_USER.child(currentUid!).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            let user = User(dictionary: dictionary)
            completion(user)
        }
    }
}
