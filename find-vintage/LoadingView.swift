//
//  LoadingView.swift
//  find-vintage
//
//  Created by hiraku on 2025/02/09.
//


import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Text("Searching...")
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
        }
    }
}