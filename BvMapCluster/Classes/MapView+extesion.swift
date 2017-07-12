//
//  MapView+extesion.swift
//  Pods
//
//  Created by Adrian Apodaca on 11/7/17.
//
//

import Foundation
import MapKit
import ClusterKit

func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType)
    -> ValueType {
        if let associated = objc_getAssociatedObject(base, key)
            as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject(base, key, associated,
                                 .OBJC_ASSOCIATION_RETAIN)
        return associated
}

func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType) {
    objc_setAssociatedObject(base, key, value,
                             .OBJC_ASSOCIATION_RETAIN)
}

public var assoKeyClusterManager: UInt8 = 0
public var assoKeyCluster: UInt8 = 1

extension MKMapView: CKMap {
    /**
     * Zoom uses an exponentional scale, where zoom 0 represents the entire world as a
     * 256 x 256 square. Each successive zoom level increases magnification by a factor of 2. So at
     * zoom level 1, the world is 512x512, and at zoom level 2, the entire world is 1024x1024.
     */
    public var zoom: Double {
        return log2(360 * (Double(self.frame.size.width / 256.0) / self.region.span.longitudeDelta))
    }

    
    /**
     Shows the specified cluster centered on screen at the greatest possible zoom level.
     
     @param cluster  The cluster to show.
     @param animated Specify YES if you want the map view to animate the transition to the cluster rectangle or NO if you want the map to center on the specified cluster immediately.
     */
    public func showCluster(_ cluster: CKCluster, animated: Bool) {
        self.showCluster(cluster, edgePadding: .zero, animated: animated)
    }
    
    /**
     Shows the specified cluster centered on screen at the greatest possible zoom level with the given edge padding.
     
     @param cluster  The cluster to show.
     @param insets   The amount of additional space (measured in screen points) to make visible around the specified rectangle.
     @param animated Specify YES if you want the map view to animate the transition to the cluster rectangle or NO if you want the map to center on the specified cluster immediately.
     */
    public func showCluster(_ cluster: CKCluster, edgePadding insets:UIEdgeInsets,  animated: Bool) {
        var zoomRect: MKMapRect = MKMapRectNull
        for annotation: CKAnnotation in cluster.annotations {
            var pointRect = MKMapRect()
            pointRect.origin = MKMapPointForCoordinate(annotation.coordinate)
            pointRect.size = MKMapSizeMake(0.1, 0.1)
            zoomRect = MKMapRectUnion(zoomRect, pointRect)
        }
        setVisibleMapRect(zoomRect, edgePadding: insets, animated: animated)

    }
    
    public var clusterManager: CKClusterManager {
        get {
            return associatedObject(base:self, key: &assoKeyClusterManager){
                let response = CKClusterManager()
                response.map = self
                return response
            } // Set the initial value of the var
        }
        set { associateObject(base:self, key: &assoKeyClusterManager, value: newValue) }
    }
    
    public func add(_ cluster: CKCluster) {
        self.addAnnotation(cluster)
    }
    
    public func remove(_ cluster: CKCluster) {
        self.removeAnnotation(cluster)
    }
    
    public func move(_ cluster: CKCluster, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: ((Bool) -> Void)? = nil) {
        cluster.coordinate = from
        let animations: ((_: Void) -> Void) = {() -> Void in
            cluster.coordinate = to
        }
        if let delegate = clusterManager.delegate, delegate.responds(to: #selector(CKClusterManagerDelegate.clusterManager(_:performAnimations:completion:))) {
            delegate.clusterManager?(clusterManager, performAnimations: animations, completion: completion)
        } else {
            UIView.animate(withDuration: TimeInterval(clusterManager.animationDuration), delay: 0, options: clusterManager.animationOptions, animations: animations, completion: completion)
        }
    }
    
    public func select(_ cluster: CKCluster, animated: Bool) {
        self.selectAnnotation(cluster, animated: animated)
    }
    
    public func deselect(_ cluster: CKCluster, animated: Bool) {
        self.deselect(cluster, animated: animated)
    }
    
}

extension MKAnnotation {
    
    weak public var cluster: CKCluster? {
        get {
            return associatedObject(base:self, key: &assoKeyCluster){ return CKCluster() } // Set the initial value of the var
        }
        set {
            if let newValue = newValue {
                associateObject(base:self, key: &assoKeyCluster, value: newValue)
            }
        }
    }
}
