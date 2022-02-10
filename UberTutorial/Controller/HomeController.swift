//
//  HomeController.swift
//  UberTutorial
//
//  Created by 张铁林 on 2022/2/4.
//

import UIKit
import Firebase
import MapKit
import GeoFire

private let reuseIdentifier = "LocationCell"
private let annotionIdentifier = "DriverAnnotion"
private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init(){
        self = .showMenu
    }
}

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    private var searchResults = [MKPlacemark]()
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    private var user: User? {
        didSet{
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            } else {
                observeTrips()
            }
        }
    }
    private var trip: Trip?{
        didSet{
            guard let user = user else { return }
            if user.accountType == .driver {
                guard let trip = trip else { return }
                let controller = PickupController(trip: trip)
                controller.delegate = self
                controller.modalPresentationStyle = .fullScreen
                self.present(controller, animated: true, completion: nil)
            } else {
                print("DEBUG: Show ride action view for accepted trip...")
            }
        }
    }
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    private let rideActionView = RideActionView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoginedInn()
        enableLocationService()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let trip = trip else { return }
        print("DEBUG: Trip state is \(trip.state)")
    }
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed(){
        switch actionButtonConfig {
        case .showMenu:
            print("DEBUG: Handle show menu")
        case .dismissActionView:
            removeAnnotationAndOverlay()
            mapView.showAnnotations(mapView.annotations, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.configureActionButton(config: .showMenu)
                self.inputActivationView.alpha = 1
                self.animateRiderActionView(shouldShow: false)
            }
        }
    }
    
    // MARK: - API
    
    func observeCurrentTrip(){
        Service.shared.observeCurrentTrip { trip in
            self.trip = trip
            
            if trip.state == .accepted {
                self.shouldPresentLoadingView(false)
                guard let driverUid = trip.driverUid else { return }
                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self.animateRiderActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
            }
        }
    }
    
    func fetchUserData(){
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { user in
            self.user = user
        }
    }
    
    func fetchDrivers(){
        guard let location = locationManager?.location else { return }
        Service.shared.fetchDrivers(location: location) { driver in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            var isDriverVisible: Bool {
                return self.mapView.annotations.contains { annotation in
                    guard let driverAnno = annotation as? DriverAnnotation else { return false }
                    if driverAnno.uid == driver.uid {
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                        return true
                    }
                    return false
                }
            }
            if !isDriverVisible {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func observeTrips(){
        Service.shared.observeTrips { trip in
            self.trip = trip
        }
    }
    
    func checkIfUserIsLoginedInn(){
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        } else {
            configure()
        }
    }
    
    func signOut(){
        do{
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        } catch {
            print("DEBUG: Error signing out")
        }
    }
    // MARK: - Help Functions
    
    func configure(){
        configureUI()
        fetchUserData()
    }
    
    fileprivate func configureActionButton(config: ActionButtonConfiguration){
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    func configureUI(){
        configureMapView()
        configRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        
        configureTableView()
    }
    
    func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
    }
    
    func configureMapView(){
        mapView.delegate = self
        view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    func configureLocationInputView(){
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            self.tableView.frame.origin.y = self.locationInputViewHeight
        }
    }
    
    func configRideActionView(){
        rideActionView.delegate = self
        view.addSubview(rideActionView)
        
        rideActionView.frame = CGRect(x: 0.0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    func configureTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0.0, y: view.frame.height, width: view.frame.width, height: height)
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil){
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    func animateRiderActionView(shouldShow : Bool, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil, user: User? = nil){
        let yOrign = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrign
        }
        if shouldShow {
            guard let config = config else { return }
            if let destination = destination {
                rideActionView.destination = destination
            }
            if let user = user {
                rideActionView.user = user
            }
            rideActionView.configureUI(withConfig: config)
        }
    }
}

// MARK: - MapView Help Function

private extension HomeController {
    func searchBy(naturalLanguage: String, completion: @escaping([MKPlacemark]) -> Void){
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguage
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard let response = response else { return }
            response.mapItems.forEach { item in
                results.append(item.placemark)
            }
            completion(results)
        }
    }
    
    func generatePolyline(toDestination destination: MKMapItem){
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { response, error in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationAndOverlay(){
        mapView.annotations.forEach { annotation in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
}

extension HomeController: CLLocationManagerDelegate {
    func enableLocationService(){
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            print("DEBUG: Not determined...")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth alawys...")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Auth when in use...")
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else { return }
        guard user.accountType == .driver else { return }
        guard let location = userLocation.location else { return }
        Service.shared.updateDriverLocation(location: location)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotionIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route{
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}

// MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func executeSearch(query: String) {
        searchBy(naturalLanguage: query) { results in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5) {
                self.inputActivationView.alpha = 1
            }
        }
    }
}

// MARK: - UITableViewDelegate/Databasource

extension HomeController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Test"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        dismissLocationView { _ in
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            let annotations = self.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self)})
//            self.mapView.showAnnotations(annotations, animated: true)
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRiderActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        shouldPresentLoadingView(true, message: "Finding you a ride...")
        Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { err, ref in
            if let error =  err {
                print("DEBUG: Failed to upload trip with error \(error.localizedDescription)")
                return
            }
            UIView.animate(withDuration: 0.3) {
                self.rideActionView.frame.origin.y = self.view.frame.height
            }
        }
    }
    
    func cancelTrip() {
        Service.shared.cancelTrip { error, ref in
            if let error = error {
                print("DEBUG: Error deleting trip\(error.localizedDescription)")
                return
            }
            self.centerMapOnUserLocation()
            self.animateRiderActionView(shouldShow: false)
            self.removeAnnotationAndOverlay()
              
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        }
    }
}

// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        let anno = MKPointAnnotation()
        anno.coordinate = trip.pickupCoordinates
        mapView.addAnnotation(anno)
        mapView.selectAnnotation(anno, animated: true)
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        Service.shared.observeTripCancelled(trip: trip) {
            self.removeAnnotationAndOverlay()
            self.animateRiderActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.presentAlertController(withTitle: "Oops",
                                        message: "The passenger has decided to cancelled this ride, Press OK to continue.")
        }
        
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self.animateRiderActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}
