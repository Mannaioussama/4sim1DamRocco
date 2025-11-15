//
//  MapView.swift
//  NEXO
//
//  Created by ROCCO 4X on 12/11/2025.
//

import SwiftUI
import MapKit

/// UIKit MapView wrapper for SwiftUI with region + selected coordinate bindings
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
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

        // Use the bound region as initial region
        mapView.setRegion(region, animated: false)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Keep map centered/zoomed to the bound region
        if !mapView.region.isApproximatelyEqual(to: region) {
            mapView.setRegion(region, animated: true)
        }

        // Update pin annotation
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

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Push user-driven region changes back to SwiftUI binding
            if !mapView.region.isApproximatelyEqual(to: parent.region) {
                parent.region = mapView.region
            }
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

private extension MKCoordinateRegion {
    func isApproximatelyEqual(to other: MKCoordinateRegion, epsilon: CLLocationDegrees = 0.0001) -> Bool {
        abs(center.latitude - other.center.latitude) < epsilon &&
        abs(center.longitude - other.center.longitude) < epsilon &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < epsilon &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < epsilon
    }
}
