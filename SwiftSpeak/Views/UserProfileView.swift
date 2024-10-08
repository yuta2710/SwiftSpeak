//
//  UserProfileView.swift
//  SwiftSpeak
//
//  Created by Nguyen Phuc Loi on 05/10/2024.
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        ZStack {
            VStack {
                if let profile = authManager.userProfile {
                    VStack {
                        Text(profile.id)
                        
                        Text(profile.name)
                        
                        Text(profile.email)
                    }
                    
                }
                Button(action: {
                    Task.init {
                        await authManager.signOut()
                        Message.buildLogInfo("[SUCCESS]: Log out successfully")
                    }
                }, label: {
                    Text("Log Out")
                    
                })
            }
            
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(AuthenticationManager())
}
