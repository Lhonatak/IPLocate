//
//  MainTabView.swift
//  IPLocate
//
//  Created by Caitsy on 07/04/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            IPInputView()
                .tabItem {
                    Image(systemName: "location.magnifyingglass")
                    Text("Locate IP")
                }
            
            UserProfileView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Saved")
                }
        }
    }
}

#Preview {
    MainTabView()
}