//
//  EditView.swift
//  BucketList
//
//  Created by Наташа Спиридонова on 03.09.2025.
//

import SwiftUI

struct EditView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: ViewModel
    
    init(location: Location, onSave: @escaping (Location) -> Void) {
        self._viewModel = State(
            initialValue: ViewModel(location: location, onSave: onSave)
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название места", text: $viewModel.name)
                    TextField("Описание", text: $viewModel.description)
                }
                
                Section("Поблизости...") {
                    switch viewModel.loadingState {
                    case .loaded:
                        ForEach(viewModel.pages, id: \.pageid) { page in
                            Text(page.title)
                                .font(.headline)
                            + Text(": ") +
                            Text(page.description)
                                .italic()
                        }
                    case .loading:
                        Text("Загрузка...")
                    case .failed:
                        Text("Попробуйте позже.")
                    }
                }
            }
            .navigationTitle("Детали места")
            .toolbar {
                Button("Сохранить") {
                    viewModel.saveLocation()
                    dismiss()
                }
            }
            .task {
                await viewModel.featchNearbyPlaces()
            }
        }
    }
}

#Preview {
    EditView(location: .example) { _ in }
}
