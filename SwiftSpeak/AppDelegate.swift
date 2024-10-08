//
//  AppDelegate.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 4/10/24.
//

import Foundation
import UIKit
import FacebookCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        let handleByFacebook = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        let handleByGoogle = GIDSignIn.sharedInstance.handle(url)
        
        return handleByFacebook || handleByGoogle
    }
}
