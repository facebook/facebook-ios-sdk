/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

// swiftformat:disable indent
@objcMembers
final class TestAppEvents: TestEventLogger,
                           _SourceApplicationTracking,
                           _AppEventsConfiguring,
                           _ApplicationActivating,
                           _ApplicationLifecycleObserving,
                           _ApplicationStateSetting {
  // swiftformat:enable indent
  var wasActivateAppCalled = false
  var wasStartObservingApplicationLifecycleNotificationsCalled = false
  var capturedApplicationState: UIApplication.State = .inactive
  var wasRegisterAutoResetSourceApplicationCalled = false
  var capturedSetSourceApplication: String?
  var capturedSetSourceApplicationURL: URL?
  var capturedCodelessIndexer: _CodelessIndexing.Type?

  func activateApp() {
    wasActivateAppCalled = true
  }

  func startObservingApplicationLifecycleNotifications() {
    wasStartObservingApplicationLifecycleNotificationsCalled = true
  }

  func setApplicationState(_ state: UIApplication.State) {
    capturedApplicationState = state
  }

  var capturedConfigureGateKeeperManager: _GateKeeperManaging.Type?
  var capturedConfigureAppEventsConfigurationProvider: _AppEventsConfigurationProviding?
  var capturedConfigureServerConfigurationProvider: _ServerConfigurationProviding?
  var capturedConfigureGraphRequestFactory: GraphRequestFactoryProtocol?
  var capturedConfigureFeatureChecker: FeatureChecking?
  var capturedConfigurePrimaryDataStore: DataPersisting?
  var capturedConfigureLogger: Logging.Type?
  var capturedConfigureSettings: SettingsProtocol?
  var capturedConfigurePaymentObserver: _PaymentObserving?
  var capturedConfigureTimeSpentRecorder: (_SourceApplicationTracking & _TimeSpentRecording)?
  var capturedConfigureAppEventsStateStore: _AppEventsStatePersisting?
  var capturedConfigureEventDeactivationParameterProcessor: _AppEventsParameterProcessing?
  var capturedConfigureRestrictiveDataFilterParameterProcessor: _AppEventsParameterProcessing?
  var capturedConfigureATEPublisherFactory: _ATEPublisherCreating?
  var capturedConfigureAppEventsStateProvider: _AppEventsStateProviding?
  var capturedConfigureSwizzler: _Swizzling.Type?
  var capturedAdvertiserIDProvider: _AdvertiserIDProviding?
  var capturedOnDeviceMLModelManager: _EventProcessing?
  var capturedMetadataIndexer: _MetadataIndexing?
  var capturedSKAdNetworkReporter: _AppEventsReporter?
  var capturedUserDataStore: _UserDataPersisting?
  var capturedAEMReporter: _AEMReporterProtocol.Type?
  // swiftlint:disable:next line_length
  var capturedAppEventsUtility: (_AppEventDropDetermining & _AppEventParametersExtracting & _AppEventsUtilityProtocol & _LoggingNotifying)?
  var capturedInternalUtility: InternalUtilityProtocol?
  var capturedCAPIReporter: CAPIReporter?

  // swiftlint:disable:next function_parameter_count
  func configure(
    gateKeeperManager: _GateKeeperManaging.Type,
    appEventsConfigurationProvider: _AppEventsConfigurationProviding,
    serverConfigurationProvider: _ServerConfigurationProviding,
    graphRequestFactory: GraphRequestFactoryProtocol,
    featureChecker: FeatureChecking,
    primaryDataStore: DataPersisting,
    logger: Logging.Type,
    settings: SettingsProtocol,
    paymentObserver: _PaymentObserving,
    timeSpentRecorder: _SourceApplicationTracking & _TimeSpentRecording,
    appEventsStateStore: _AppEventsStatePersisting,
    eventDeactivationParameterProcessor: _AppEventsParameterProcessing,
    restrictiveDataFilterParameterProcessor: _AppEventsParameterProcessing,
    atePublisherFactory: _ATEPublisherCreating,
    appEventsStateProvider: _AppEventsStateProviding,
    advertiserIDProvider: _AdvertiserIDProviding,
    userDataStore: _UserDataPersisting,
    // swiftlint:disable:next line_length
    appEventsUtility: _AppEventDropDetermining & _AppEventParametersExtracting & _AppEventsUtilityProtocol & _LoggingNotifying,
    internalUtility: InternalUtilityProtocol,
    capiReporter: CAPIReporter
  ) {
    capturedConfigureGateKeeperManager = gateKeeperManager
    capturedConfigureAppEventsConfigurationProvider = appEventsConfigurationProvider
    capturedConfigureServerConfigurationProvider = serverConfigurationProvider
    capturedConfigureGraphRequestFactory = graphRequestFactory
    capturedConfigureFeatureChecker = featureChecker
    capturedConfigurePrimaryDataStore = primaryDataStore
    capturedConfigureLogger = logger
    capturedConfigureSettings = settings
    capturedConfigurePaymentObserver = paymentObserver
    capturedConfigureTimeSpentRecorder = timeSpentRecorder
    capturedConfigureAppEventsStateStore = appEventsStateStore
    capturedConfigureEventDeactivationParameterProcessor = eventDeactivationParameterProcessor
    capturedConfigureRestrictiveDataFilterParameterProcessor = restrictiveDataFilterParameterProcessor
    capturedConfigureATEPublisherFactory = atePublisherFactory
    capturedConfigureAppEventsStateProvider = appEventsStateProvider
    capturedAdvertiserIDProvider = advertiserIDProvider
    capturedUserDataStore = userDataStore
    capturedAppEventsUtility = appEventsUtility
    capturedInternalUtility = internalUtility
    capturedCAPIReporter = capiReporter
  }

  // swiftlint:disable:next function_parameter_count
  func configureNonTVComponents(
    onDeviceMLModelManager modelManager: _EventProcessing,
    metadataIndexer: _MetadataIndexing,
    skAdNetworkReporter: _AppEventsReporter?,
    codelessIndexer: _CodelessIndexing.Type,
    swizzler: _Swizzling.Type,
    aemReporter: _AEMReporterProtocol.Type
  ) {
    capturedOnDeviceMLModelManager = modelManager
    capturedMetadataIndexer = metadataIndexer
    capturedSKAdNetworkReporter = skAdNetworkReporter
    capturedCodelessIndexer = codelessIndexer
    capturedConfigureSwizzler = swizzler
    capturedAEMReporter = aemReporter
  }

  // MARK: - Source Application Tracking

  func setSourceApplication(_ sourceApplication: String?, open url: URL?) {
    capturedSetSourceApplication = sourceApplication
    capturedSetSourceApplicationURL = url
  }

  func setSourceApplication(_ sourceApplication: String?, isFromAppLink: Bool) {
    // TODO: Implement when we add coverage for MeasurementEventListener
  }

  func registerAutoResetSourceApplication() {
    wasRegisterAutoResetSourceApplicationCalled = true
  }
}
