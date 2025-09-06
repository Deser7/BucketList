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

extension ContentView {
    @Observable
    final class ViewModel {
        let savePath = URL.documentsDirectory.appending(path: "SavedPlaces")
        
        private(set) var locations: [Location]
        var selectedPlace: Location?
        var isUnlocked = false
        var isStandartMode = true
        var alertMessage: String?
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
                            if let authError = authenticationError as? LAError {
                                self?.handleAuthenticationError(authError)
                            } else {
                                self?.showErrorAlert("Ошибка аутентификации", "Неизвестная ошибка")
                            }
                        }
                    }
                }
            } else {
                if let error = error {
                    handleBiometryAvailabilityError(error)
                } else {
                    showErrorAlert("Ошибка", "Биометрия недоступна")
                }
            }
        }
        
        private func handleAuthenticationError(_ error: LAError) {
            switch error.code {
            case .userCancel:
                break
            case .userFallback:
                showErrorAlert("Альтернативный метод", "Выбран альтернативный метод аутентификации")
            case .biometryNotAvailable:
                showErrorAlert("Биометрия недоступна", "Биометрия не поддерживается на этом устройстве")
            case .biometryNotEnrolled:
                showErrorAlert("Биометрия не настроена", "Настройте Touch ID или Face ID в настройках устройства")
            case .biometryLockout:
                showErrorAlert("Биометрия заблокирована", "Слишком много неудачных попыток. Используйте пароль устройства")
            case .systemCancel:
                showErrorAlert("Отменено системой", "Аутентификация была отменена системой")
            case .passcodeNotSet:
                showErrorAlert("Пароль не установлен", "Установите пароль устройства в настройках")
            case .touchIDNotAvailable:
                showErrorAlert("Touch ID недоступен", "Touch ID не поддерживается на этом устройстве")
            case .touchIDNotEnrolled:
                showErrorAlert("Touch ID не настроен", "Настройте Touch ID в настройках устройства")
            case .touchIDLockout:
                showErrorAlert("Touch ID заблокирован", "Touch ID заблокирован. Используйте пароль устройства")
            case .notInteractive:
                showErrorAlert("Не интерактивно", "Аутентификация не может быть выполнена в данный момент")
            case .biometryNotPaired:
                showErrorAlert("Биометрия не сопряжена", "Биометрия не сопряжена с устройством")
            case .biometryDisconnected:
                showErrorAlert("Биометрия отключена", "Биометрия отключена от устройства")
            case .invalidContext:
                showErrorAlert("Неверный контекст", "Ошибка контекста аутентификации")
            case .authenticationFailed:
                showErrorAlert("Попробуйте еще раз", "Аутентификация не удалась. Попроьуйте отпечаток пальца или лицо")
            case .appCancel:
                break
            @unknown default:
                showErrorAlert("Неизвестная ошибка", error.localizedDescription)
            }
        }
        
        private func handleBiometryAvailabilityError(_ error: NSError) {
            switch error.code {
            case LAError.biometryNotAvailable.rawValue:
                showErrorAlert("Биометрия недоступна", "Биометрия не поддерживается на этом устройстве")
            case LAError.biometryNotEnrolled.rawValue:
                showErrorAlert("Биометрия не настроена", "Настройте биометрию в настройках устройства")
            case LAError.biometryLockout.rawValue:
                showErrorAlert("Биометрия заблокирована", "Биометрия заблокирована. Используйте пароль устройства")
            case LAError.passcodeNotSet.rawValue:
                showErrorAlert("Пароль не установлен", "Установите пароль устройства в настройках")
            default:
                showErrorAlert("Ошибка биометрии", error.localizedDescription)
            }
        }
        
        private func showErrorAlert(_ title: String, _ message: String) {
            alertMessage = "\(title)\n\n\(message)"
            showAlert = true
            isUnlocked = false
        }
        
        private func tryPasswordAuthentication() {
            let fallbackContext = LAContext()
            
            if fallbackContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
                fallbackContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Введите пароль устройства") { [weak self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            self?.isUnlocked = true
                        } else {
                            self?.showErrorAlert("Ошибка пароля", "Неверный пароль или ошибка аутентификации")
                        }
                    }
                }
            } else {
                showErrorAlert("Аутентификация недоступна", "Аутентификация не настроена на этом устройстве")
            }
        }
    }
}
