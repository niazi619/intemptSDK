//
//  SceneDelegate.swift
//  DemoTracking
//
//  Created by Tanay Bhattacharjee on 25/03/20.
//  Copyright © 2020 Tanay Bhattacharjee. All rights reserved.
//

import UIKit
import Intempt
import Dispatch

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        decideInitialViewController()
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
        print("sceneWillResignActive=")
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("sceneWillEnterForeground=")
        //self.initializeIntemptTracking()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("sceneDidEnterBackground=")
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

