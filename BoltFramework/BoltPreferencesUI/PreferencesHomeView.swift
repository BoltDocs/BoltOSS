//
// Copyright (C) 2024 Bolt Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

import Factory

import BoltDocsets
import BoltLocalizations
import BoltModuleExports
import BoltServices
import BoltUIFoundation
import BoltUtils

// swiftlint:disable switch_case_on_newline

private enum UpdateCheckingFrequency: CaseIterable, CustomStringConvertible, CustomLocalizedStringResourceConvertible {

  case daily, weekly, monthly, never

  init(seconds: Int) {
    guard seconds > 0 else {
      self = .never
      return
    }
    if let value = Self.allCases.first(where: { seconds <= $0.toSeconds }) {
      self = value
    } else {
      self = Self.allCases.last!
    }
  }

  var toSeconds: Int {
    switch self {
    case .daily: 86400 // 24 * 3600
    case .weekly: 604800 // 7 * 24 * 3600
    case .monthly: 2592000 // 30 * 24 * 3600
    case .never: -1
    }
  }

  var description: String {
    switch self {
    case .daily: "Daily"
    case .weekly: "Weekly"
    case .monthly: "Monthly"
    case .never: "Never"
    }
  }

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .daily: "Preferences-Home-DocsetUpdates-updateCheckingFrequencyDaily".boltLocalizedStringResource
    case .weekly: "Preferences-Home-DocsetUpdates-updateCheckingFrequencyWeekly".boltLocalizedStringResource
    case .monthly: "Preferences-Home-DocsetUpdates-updateCheckingFrequencyMonthly".boltLocalizedStringResource
    case .never: "Preferences-Home-DocsetUpdates-updateCheckingFrequencyNever".boltLocalizedStringResource
    }
  }

}

// swiftlint:enable switch_case_on_newline

private class PreferencesHomeViewModel: ObservableObject {

  @Published var disablesPrivateBrowsing = false
  @Published var enablesDesktopMode = false
  @Published var updateCheckingFrequency = UpdateCheckingFrequency.never
  @Published var webViewInspectable = false

  @Injected(\.docsetUpdateChecker)
  private var docsetUpdateChecker: DocsetUpdateChecker

  private var sceneState: SceneState

  init(sceneState: SceneState) {
    self.sceneState = sceneState

    UserDefaults.standard.publisher(for: \.disablesPrivateBrowsing)
      .assign(to: &$disablesPrivateBrowsing)
    UserDefaults.standard.publisher(for: \.enablesDesktopMode)
      .assign(to: &$enablesDesktopMode)
    UserDefaults.standard.publisher(for: \.updateCheckingFrequency)
      .map(UpdateCheckingFrequency.init(seconds:))
      .assign(to: &$updateCheckingFrequency)

    UserDefaults.standard.publisher(for: \.webViewInspectable)
      .assign(to: &$webViewInspectable)
  }

  func checkForDocsetUpdates() {
    Task { [sceneState] in
      let updatableEntries = await docsetUpdateChecker.fetchDocsetUpdates(useCachedEntries: false)
      let updatableEntriesCount = updatableEntries.count
      if updatableEntriesCount > 0 {
        await GlobalUI.presentAlertController(
          UIAlertController.alert(
            withTitle: "Preferences-Home-DocsetUpdatesAvailableAlert-title".boltLocalized,
            message: "Preferences-Home-DocsetUpdatesAvailableAlert-message".boltLocalized(updatableEntriesCount),
            confirmAction: (
              UIKitLocalizations.ok,
              UIAlertAction.Style.default, {
                sceneState.dispatch(action: .onPresentUpdates)
              }
            ),
            cancelAction: (UIKitLocalizations.cancel, { })
          )
        )
      } else {
        await GlobalUI.presentAlertController(
          UIAlertController.alert(
            withTitle: "Preferences-Home-DocsetsUpToDateAlert-title".boltLocalized,
            message: "Preferences-Home-DocsetsUpToDateAlert-message".boltLocalized,
            confirmAction: (UIKitLocalizations.ok, .default, nil)
          )
        )
      }
    }
  }

}

public struct PreferencesHomeView: View {

  @Environment(\.dismiss)
  private var dismiss: DismissAction

  @StateObject private var viewModel: PreferencesHomeViewModel

  @Injected(\.distributionService)
  private var distributionService: DistributionService?

  @Injected(\.crashesService)
  private var crashesService: CrashesService?

  @State private var isTypeBrowserPresented = false

  @MainActor @State private var isCacheClearing = false {
    didSet {
      if isCacheClearing {
        GlobalUI.presentAlertController(
          UIAlertController.alert(
            withTitle: "Preferences-Home-CacheClear-alertTitle".boltLocalized,
            message: "Preferences-Home-CacheClear-alertMessage".boltLocalized
          )
        )
      } else {
        GlobalUI.dismissCurrentAlertController()
      }
    }
  }

  public init(sceneState: SceneState) {
    _viewModel = StateObject(wrappedValue: PreferencesHomeViewModel(sceneState: sceneState))
  }

  public var body: some View {
    NavigationView {
      List {
        Section("Preferences-Home-Appearance-sectionTitle".boltLocalized) {
          NavigationLink(
            "Preferences-Home-Appearance-tintColorButtonTitle".boltLocalized,
            destination: PreferencesTintColorView()
          )
          Button("Preferences-Home-Appearance-changeIconButtonTitle".boltLocalized) {
            GlobalUI.showMessageToast(
              withText: "Preferences-Home-Appearance-toastToBeImplemented".boltLocalized
            )
          }
        }
        Section("Preferences-Home-General-sectionTitle".boltLocalized) {
          BoltToggle(
            isOn: Binding(
              get: { !viewModel.disablesPrivateBrowsing },
              set: { UserDefaults.standard.disablesPrivateBrowsing = !$0 }
            )
          ) {
            Text("Preferences-Home-General-privateBrowsingToggleTitle".boltLocalized)
          }
          BoltToggle(
            isOn: Binding(
              get: { viewModel.enablesDesktopMode },
              set: { UserDefaults.standard.enablesDesktopMode = $0 }
            )
          ) {
            Text("Preferences-Home-General-desktopModeToggleTitle".boltLocalized)
          }
          Button("Preferences-Home-General-clearCacheButtonTitle".boltLocalized) {
            Task {
              if isCacheClearing {
                return
              }
              isCacheClearing = true
              await CacheCleaner.clearCache()
              isCacheClearing = false
            }
          }
        }
        Section("Preferences-Home-DocsetUpdates-sectionTitle".boltLocalized) {
          Picker(
            "Preferences-Home-DocsetUpdates-updateCheckingFrequencyPickerTitle".boltLocalized,
            selection: Binding<UpdateCheckingFrequency>(
              get: { viewModel.updateCheckingFrequency },
              set: { UserDefaults.standard.updateCheckingFrequency = $0.toSeconds }
            )
          ) {
            ForEach(UpdateCheckingFrequency.allCases, id: \.self) {
              Text(String(localized: $0.localizedStringResource))
            }
          }
          .pickerStyle(.navigationLink)
          Button("Preferences-Home-DocsetUpdates-checkForUpdatesButtonTitle".boltLocalized) {
            viewModel.checkForDocsetUpdates()
          }
        }
        Section("Preferences-Home-About-sectionTitle".boltLocalized) {
          NavigationLink(
            "Preferences-Home-About-aboutButtonTitle".boltLocalized,
            destination: PreferencesAboutView()
          )
        }
        if RuntimeEnvironment.isInternalBuild {
          Section("Preferences-Home-InternalDiagnostics-sectionTitle".boltLocalized) {
            if let distributionService = distributionService {
              Button("Preferences-Home-InternalDiagnostics-checkUpdateButtonTitle".boltLocalized) {
                distributionService.checkForUpdate()
              }
            }
            Button("Preferences-Home-InternalDiagnostics-typeBrowserButtonTitle".boltLocalized) {
              isTypeBrowserPresented.toggle()
            }
            .sheet(isPresented: $isTypeBrowserPresented) {
              PreferencesTypeBrowserView()
            }
            BoltToggle(
              isOn: Binding(
                get: { viewModel.webViewInspectable },
                set: { UserDefaults.standard.webViewInspectable = $0 }
              )
            ) {
              Text("Preferences-Home-InternalDiagnostics-webViewInspector".boltLocalized)
            }
            Button("Preferences-Home-InternalDiagnostics-resetData".boltLocalized) {
              if isCacheClearing {
                return
              }
              isCacheClearing = true
              CacheCleaner.removeAllFiles {
                isCacheClearing = false
                exit(0)
              }
            }
            .tint(Color.red)
            internalSectionItems
          }
        }
        if let crashesService = crashesService {
          Section("Preferences-Home-DebugDiagnostics-sectionTitle".boltLocalized) {
            Button("Preferences-Home-DebugDiagnostics-testCrashButtonTitle".boltLocalized) {
              crashesService.generateTestCrash()
            }
            .tint(Color.red)
          }
        }
      }
      .navigationTitle("Preferences-Home-title".boltLocalized)
      .listStyle(.insetGrouped)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(UIKitLocalizations.done, systemImage: "checkmark") {
            dismiss()
          }
          .labelStyle(.toolbar)
        }
      }
    }
    .navigationViewStyle(.stack)
  }

}
