//
//  ContentView.swift
//  ARPersistencySwiftUI
//
//  Created by Jose Castillo on 2/8/23.
//

import SwiftUI

struct ContentView : View {
    var body: some View {
        #if !targetEnvironment(simulator)
        StoryBoardView()
        #else
        Text("Hello World!")
        #endif
    }
}

#if !targetEnvironment(simulator)
struct StoryBoardView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(identifier: "AR")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
#endif

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
