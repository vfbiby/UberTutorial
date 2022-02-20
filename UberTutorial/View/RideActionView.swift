//
//  RiderActionView.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/7.
//

import UIKit
import MapKit

protocol RideActionViewDelegate: AnyObject {
    func uploadTrip(_ view: RideActionView)
    func cancelTrip()
    func pickupPassenger()
    func dropOffPassenger()
}

enum RideActionViewConfiguration{
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide: return "CONFIRM UBERX"
        case .cancel: return "CANCEL RIDE"
        case .getDirections: return "GET DIRECTIONS"
        case .pickup: return "PICKUP PASSENGER"
        case .dropOff: return "DROP OFF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}

class RideActionView: UIView {
    
    // MARK: - Properties
    
    var destination: MKPlacemark? {
        didSet{
            titleLable.text = destination?.name
            addressLable.text = destination?.title
        }
    }
    
    var buttonAction = ButtonAction()
    weak var delegate:RideActionViewDelegate?
    var user: User?
    
    var config = RideActionViewConfiguration(){
        didSet { configureUI(withConfig: config) }
    }
    
    private let titleLable: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let addressLable: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        
        view.addSubview(infoViewLabel)
        infoViewLabel.centerX(inView: view)
        infoViewLabel.centerY(inView: view)
        
        return view
    }()
    
    private let infoViewLabel: UILabel = {
        let label = UILabel()
        label.text = "X"
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = .white
        return label
    }()
    
    private let uberInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "UberX"
        label.textAlignment = .center
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.setTitle("CONFIRM UBERX", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLable, addressLable])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchor(top: stack.bottomAnchor, paddingTop: 16)
        infoView.setDimensions(height: 60, width: 60)
        infoView.layer.cornerRadius = 60 / 2
        
        addSubview(uberInfoLabel)
        uberInfoLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8)
        uberInfoLabel.centerX(inView: self)
        
        let seperateView = UIView()
        seperateView.backgroundColor = .lightGray
        addSubview(seperateView)
        seperateView.anchor(top: uberInfoLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 4, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(left: leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: rightAnchor, paddingLeft: 12, paddingBottom: 12, paddingRight: 12, height: 50)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed(){
        switch buttonAction {
        case .requestRide:
            delegate?.uploadTrip(self)
        case .cancel:
            delegate?.cancelTrip()
        case .getDirections:
            print("DEBUG: Handle get direction...")
        case .pickup:
            delegate?.pickupPassenger()
        case .dropOff:
            delegate?.dropOffPassenger()
        }
    }
    
    // MARK: - Help Functions
    
    private func configureUI(withConfig config: RideActionViewConfiguration){
        switch config {
        case .requestRide:
            buttonAction = .requestRide
            actionButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripAccepted:
            guard let user = user else { return }
            
            if user.accountType == .passenger {
                titleLable.text = "En Route To Passenger"
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            } else {
                buttonAction = .cancel
                actionButton.setTitle(buttonAction.description, for: .normal)
                titleLable.text = "Driver En Route"
            }
            infoViewLabel.text = String(user.fullname.first ?? "X")
            uberInfoLabel.text = user.fullname
            
        case .driverArrived:
            guard let user = user else { return }
            if user.accountType == .driver {
                titleLable.text = "Driver Has Arrived"
                addressLable.text = "Please meet driver at pickup location"
            }
            
        case .pickupPassenger:
            titleLable.text = "Arrived At Passenger Location"
            buttonAction = .pickup
            actionButton.setTitle(buttonAction.description, for: .normal)
            
        case .tripInProgress:
            guard let user = user else { return }
            if user.accountType == .driver {
                actionButton.setTitle("TRIP IN PROGRESS", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .getDirections
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            titleLable.text = "En Route To Destination"
            
        case .endTrip:
            guard let user = user else { return }
            if user.accountType == .driver {
                actionButton.setTitle("ARRIVED AT DESTINATION", for: .normal)
                actionButton.isEnabled = false
            } else {
                buttonAction = .dropOff
                actionButton.setTitle(buttonAction.description, for: .normal)
            }
            titleLable.text = "Arrived at Destination"
        }
    }
}
