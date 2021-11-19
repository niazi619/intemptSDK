//
//  SceneDelegate.swift
//  DemoTracking
//
//  Created by Tanay Bhattacharjee on 25/03/20.
//  Copyright © 2020 Tanay Bhattacharjee. All rights reserved.
//

import UIKit
import AppTrackingTransparency
import Intempt
import Dispatch

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        decideInitialViewController()
        
        APP_DELEGATE.delay(1){
            self.requestTrackingPermission()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("sceneWillEnterForeground=",sceneWillEnterForeground)
        //self.initializeIntemptTracking()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    private func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                    case .authorized:
                        // Tracking authorization dialog was shown
                        // and we are authorized
                        print("Tracking authorized.")
                        
                        UserDefaults.standard.set(true, forKey: "TrackingEnabled")
                        // Now that we are authorized we can get the IDFA
                        DispatchQueue.main.async {
                            self.decideInitialViewController()
                            self.initializeIntemptTracking()
                        }
                    case .denied:
                        // Tracking authorization dialog was
                        // shown and permission is denied
                        print("Denied. Please turn on app tracking to enable app analytics.")
                        UserDefaults.standard.set(false, forKey: "TrackingEnabled")
                    case .notDetermined:
                        // Tracking authorization dialog has not been shown
                        print("Not determined.")
                    case .restricted:
                        print("Restricted. Please turn on app tracking to enable app analytics.")
                        UserDefaults.standard.set(false, forKey: "TrackingEnabled")
                    @unknown default:
                        print("Unknown.")
                }
            }
        }
        else {
            initializeIntemptTracking()
        }
    }
    
    private func initializeIntemptTracking() {
        //Initialize Intempt SDK
        let intemptConfig = IntemptConfig(queueEnabled: true, withItemsInQueue: 7, withTimeBuffer: 15, withInitialDelay: 0.3, withInputTextCaptureDisabled: false)
        IntemptTracker.tracking(withOrgId: IntemptOptions.orgId, withSourceId: IntemptOptions.sourceId, withToken: IntemptOptions.token, withConfig: intemptConfig) { (status, result, error) in
            if(status) {
                if let dictResult = result as? [String: Any] {
                    print(dictResult)
                }
            }
            else {
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
        
    }
    
    func decideInitialViewController() {
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController")
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

