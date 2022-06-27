//
//  mapViewController.swift
//  My Travel Book
//
//  Created by Furkan Ceylan on 22.06.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class mapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var placeTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var latitude = Double()
    var longitude = Double()
    
    var chooseId = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonClicked))
        
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        
        // User location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        
        // Annotation
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(annotation(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizerView = UITapGestureRecognizer(target: self, action: #selector(keyboardClosed))
        view.addGestureRecognizer(gestureRecognizerView)
        
        // Data Extraction
        if chooseId != ""{
            navigationItem.rightBarButtonItem?.isEnabled = false
            gestureRecognizer.isEnabled = false
            placeTextField.isEnabled = false
            descriptionTextField.isEnabled = false
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Map")
            fetchRequest.predicate = NSPredicate(format: "id = %@", chooseId)
            do{
                let results = try context.fetch(fetchRequest)
                for result in results as! [NSManagedObject] {
                    locationManager.stopUpdatingLocation()
                    
                    placeTextField.text = result.value(forKey: "place") as? String
                    descriptionTextField.text = result.value(forKey: "descriptions") as? String
                    let latitude = result.value(forKey: "latitude") as! CLLocationDegrees
                    let longitude = result.value(forKey: "longitude") as! CLLocationDegrees
                    self.latitude = latitude
                    self.longitude = longitude
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let region = MKCoordinateRegion(center: location, span: span)
                    mapView.setRegion(region, animated: true)
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    annotation.title = placeTextField.text
                    annotation.subtitle = descriptionTextField.text
                    mapView.addAnnotation(annotation)
                }
            }catch{
                print("Error")
            }
            
            
        }else if chooseId == ""{
            
        }else{
            print("Error")
        }
        
    }
    
    // Add detail button
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "lkgfnragn"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .systemBlue
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chooseId != ""{
            let requestLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
            print("\(latitude)")
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placesMarks, error in
                if let placesMarks = placesMarks {
                    if placesMarks.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placesMarks[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.placeTextField.text
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    // Keyboard Closed func
    @objc func keyboardClosed() {
        view.endEditing(true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if chooseId == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            locationManager.stopUpdatingLocation()
        }
        
    }
    
    @objc func annotation(gestureRecognizer : UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            if (placeTextField.text != "") && (descriptionTextField.text != ""){
                let touchPoint = gestureRecognizer.location(in: mapView)
                let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchCoordinate
                annotation.title = placeTextField.text?.capitalized
                annotation.subtitle = descriptionTextField.text?.capitalized
                mapView.addAnnotation(annotation)
                
                latitude = touchCoordinate.latitude
                longitude = touchCoordinate.longitude
                
            }else{
                let alertMessage = UIAlertController(title: "Warning", message: "Text field cannot be blank.", preferredStyle: .alert)
                let okButton = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                alertMessage.addAction(okButton)
                self.present(alertMessage, animated: true, completion: nil)
            }
        }
    }
    
    @objc func saveButtonClicked(){
        if (placeTextField.text != "") && (descriptionTextField.text != ""){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext

            let mapData = NSEntityDescription.insertNewObject(forEntityName: "Map", into: context)
            mapData.setValue(placeTextField.text, forKey: "place")
            mapData.setValue(descriptionTextField.text, forKey: "descriptions")
            mapData.setValue(UUID(), forKey: "id")
            mapData.setValue(self.latitude, forKey: "latitude")
            mapData.setValue(self.longitude, forKey: "longitude")
            
            let alert = UIAlertController(title: "Success", message: "Registration Success", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "Ok", style: .cancel) { alert in
            self.navigationController?.popViewController(animated: true)
                do{
                    try context.save()
                }catch{
                    print("Error")
                }
            }
            alert.addAction(okButton)
            self.present(alert, animated: true, completion: nil)
        
        }else{
            let alertMessage = UIAlertController(title: "Warning", message: "Text field cannot be blank.", preferredStyle: .alert)
            let okButton = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
            alertMessage.addAction(okButton)
            self.present(alertMessage, animated: true, completion: nil)
        }
    }


}
