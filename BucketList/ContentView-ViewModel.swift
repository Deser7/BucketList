//
//  ContentView-ViewModel.swift
//  BucketList
//
//  Created by Наташа Спиридонова on 03.09.2025.
//

import CoreLocation
import Foundation
import LocalAuthentication
import MapKit

private enum AuthenticationErrorType {
    case userCancelled
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case passcodeNotSet
    case authenticationFailed
    case unknown(String)
    
    var title: String {
        switch self {
        case .userCancelled:
            return "Отменено"
        case .biometryNotAvailable:
            return "Биометрия недоступна"
        case .biometryNotEnrolled:
            return "Биометрия не настроена"
        case .biometryLockout:
            return "Биометрия заблокирована"
        case .passcodeNotSet:
            return "Пароль не установлен"
        case .authenticationFailed:
            return "Ошибка аутентификации"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
    
    var message: String {
        switch self {
        case .userCancelled:
            return "Аутентификация отменена пользователем"
        case .biometryNotAvailable:
            return "Биометрия не поддерживается на этом устройстве"
        case .biometryNotEnrolled:
            return "Настройте Touch ID или Face ID в настройках устройства"
        case .biometryLockout:
            return "Слишком много неудачных попыток. Используйте пароль устройства"
        case .passcodeNotSet:
            return "Установите пароль устройства в настройках"
        case .authenticationFailed:
            return "Попробуйте еще раз"
        case .unknown(let description):
            return description
        }
    }
}

extension ContentView {
    @Observable
    final class ViewModel {
        let savePath = URL.documentsDirectory.appending(path: "SavedPlaces")
        
        private(set) var locations: [Location]
        var alertMessage: String?
        var alertTitle: String?
        var selectedPlace: Location?
        var isUnlocked = false
        var isStandartMode = true
        
        var showAlert = false
        
        init() {
            do {
                let data = try Data(contentsOf: savePath)
                locations = try JSONDecoder().decode([Location].self, from: data)
            } catch {
                locations = []
            }
        }
        
        func save() {
            do {
                let data = try JSONEncoder().encode(locations)
                try data.write(to: savePath, options: [.atomic, .completeFileProtection])
            } catch {
                print("Unable to save data.")
            }
        }
        
        func addLocation(at point: CLLocationCoordinate2D) {
            let newLocation = Location(
                id: UUID(),
                name: "Новое место",
                description: "",
                latitude: point.latitude,
                longitude: point.longitude
            )
            locations.append(newLocation)
            save()
        }
        
        func update(location: Location) {
            guard let selectedPlace else { return }
            
            if let index = locations.firstIndex(of: selectedPlace) {
                locations[index] = location
                save()
            }
        }
        
        func authenticate() {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Пожалуйста, аутентифицируйтесь для разблокировки ваших мест."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            self?.isUnlocked = true
                        } else {
                            if let authError = authenticationError {
                                self?.handleError(authError)
                            } else {
                                self?.handleError(NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Неизвестная ошибка"]))
                            }
                        }
                    }
                }
            } else {
                if let error = error {
                    handleError(error)
                } else {
                    handleError(NSError(domain: "BiometryError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Биометрия недоступна"]))
                }
            }
        }
        
        private func handleError(_ error: Error) {
            let errorType: AuthenticationErrorType
            
            if let laError = error as? LAError {
                errorType = mapLAError(laError)
            } else {
                errorType = .unknown(error.localizedDescription)
            }
            if case .userCancelled = errorType {
                return
            }
            
            showErrorAlert(errorType.title, errorType.message)
        }

        private func mapLAError(_ error: LAError) -> AuthenticationErrorType {
            switch error.code {
            case .userCancel, .appCancel:
                return .userCancelled
            case .biometryNotAvailable, .touchIDNotAvailable:
                return .biometryNotAvailable
            case .biometryNotEnrolled, .touchIDNotEnrolled:
                return .biometryNotEnrolled
            case .biometryLockout, .touchIDLockout:
                return .biometryLockout
            case .passcodeNotSet:
                return .passcodeNotSet
            case .authenticationFailed:
                return .authenticationFailed
            default:
                return .unknown(error.localizedDescription)
            }
        }

        private func mapNSError(_ error: NSError) -> AuthenticationErrorType {
            switch error.code {
            case LAError.biometryNotAvailable.rawValue:
                return .biometryNotAvailable
            case LAError.biometryNotEnrolled.rawValue:
                return .biometryNotEnrolled
            case LAError.biometryLockout.rawValue:
                return .biometryLockout
            case LAError.passcodeNotSet.rawValue:
                return .passcodeNotSet
            default:
                return .unknown(error.localizedDescription)
            }
        }
        
        private func showErrorAlert(_ title: String, _ message: String) {
            alertMessage = message
            alertTitle = title
            isUnlocked = false
        }
    }
}
