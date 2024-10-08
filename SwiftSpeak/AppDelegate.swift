//
//  AppDelegate.swift
//  SwiftSpeak
//
//  Created by Xuan Loc on 4/10/24.
//

import FacebookCore
import Firebase
import GoogleSignIn
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication
			.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		FirebaseApp.configure()
		ApplicationDelegate.shared.application(
			application,
			didFinishLaunchingWithOptions: launchOptions
		)
		return true
	}

	func application(
		_ app: UIApplication, open url: URL,
		options: [UIApplication.OpenURLOptionsKey: Any] = [:]
	) -> Bool {
		ApplicationDelegate.shared.application(
			app,
			open: url,
			sourceApplication: options[
				UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
			annotation: options[UIApplication.OpenURLOptionsKey.annotation]
		)
	}
}
