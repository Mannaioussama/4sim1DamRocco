//
//  MapView.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import SwiftUI
import MapKit

/// UIKit MapView wrapper for SwiftUI
struct MapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D?
    var onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)
        
        // Set initial region (Tunis)
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(initialRegion, animated: false)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update pin
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        if let coordinate = coordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onTap(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "LocationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                
                // Create custom pin view
                let pinView = createCustomPinView()
                annotationView?.addSubview(pinView)
                annotationView?.frame = pinView.frame
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        private func createCustomPinView() -> UIView {
            let pinView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            pinView.backgroundColor = .clear
            
            let circleView = UIView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
            circleView.backgroundColor = .orange
            circleView.layer.cornerRadius = 20
            circleView.layer.shadowColor = UIColor.black.cgColor
            circleView.layer.shadowOpacity = 0.3
            circleView.layer.shadowOffset = CGSize(width: 0, height: 2)
            circleView.layer.shadowRadius = 4
            
            let imageView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
            imageView.frame = CGRect(x: 10, y: 10, width: 30, height: 30)
            imageView.tintColor = .white
            imageView.contentMode = .scaleAspectFit
            
            circleView.addSubview(imageView)
            pinView.addSubview(circleView)
            
            return pinView
        }
    }
}
