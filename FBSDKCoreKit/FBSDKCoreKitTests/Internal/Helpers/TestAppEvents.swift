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
                           SourceApplicationTracking,
                           AppEventsConfiguring,
                           ApplicationActivating,
                           ApplicationLifecycleObserving,
                           ApplicationStateSetting {
  // swiftformat:enable indent
  var wasActivateAppCalled = false
  var wasStartObservingApplicationLifecycleNotificationsCalled = false
  var capturedApplicationState: UIApplication.State = .inactive
  var wasRegisterAutoResetSourceApplicationCalled = false
  var capturedSetSourceApplication: String?
  var capturedSetSourceApplicationURL: URL?
  var capturedCodelessIndexer: CodelessIndexing.Type?

  func activateApp() {
    wasActivateAppCalled = true
  }

  func startObservingApplicationLifecycleNotifications() {
    wasStartObservingApplicationLifecycleNotificationsCalled = true
  }

  func setApplicationState(_ state: UIApplication.State) {
    capturedApplicationState = state
  }

  var capturedConfigureGateKeeperManager: GateKeeperManaging.Type?
  var capturedConfigureAppEventsConfigurationProvider: AppEventsConfigurationProviding?
  var capturedConfigureServerConfigurationProvider: ServerConfigurationProviding?
  var capturedConfigureGraphRequestFactory: GraphRequestFactoryProtocol?
  var capturedConfigureFeatureChecker: FeatureChecking?
  var capturedConfigurePrimaryDataStore: DataPersisting?
  var capturedConfigureLogger: Logging.Type?
  var capturedConfigureSettings: SettingsProtocol?
  var capturedConfigurePaymentObserver: PaymentObserving?
  var capturedConfigureTimeSpentRecorder: (SourceApplicationTracking & TimeSpentRecording)?
  var capturedConfigureAppEventsStateStore: AppEventsStatePersisting?
  var capturedConfigureEventDeactivationParameterProcessor: AppEventsParameterProcessing?
  var capturedConfigureRestrictiveDataFilterParameterProcessor: AppEventsParameterProcessing?
  var capturedConfigureATEPublisherFactory: ATEPublisherCreating?
  var capturedConfigureAppEventsStateProvider: AppEventsStateProviding?
  var capturedConfigureSwizzler: Swizzling.Type?
  var capturedAdvertiserIDProvider: AdvertiserIDProviding?
  var capturedOnDeviceMLModelManager: EventProcessing?
  var capturedMetadataIndexer: MetadataIndexing?
  var capturedSKAdNetworkReporter: AppEventsReporter?
  var capturedUserDataStore: UserDataPersisting?
  var capturedAEMReporter: _AEMReporterProtocol.Type?
  // swiftlint:disable:next line_length
  var capturedAppEventsUtility: (AppEventDropDetermining & AppEventParametersExtracting & AppEventsUtilityProtocol & LoggingNotifying)?
  var capturedInternalUtility: InternalUtilityProtocol?
  var capturedCAPIReporter: CAPIReporter?

  // swiftlint:disable:next function_parameter_count
  func configure(
    withGateKeeperManager gateKeeperManager: GateKeeperManaging.Type,
    appEventsConfigurationProvider: AppEventsConfigurationProviding,
    serverConfigurationProvider: ServerConfigurationProviding,
    graphRequestFactory: GraphRequestFactoryProtocol,
    featureChecker: FeatureChecking,
    primaryDataStore: DataPersisting,
    logger: Logging.Type,
    settings: SettingsProtocol,
    paymentObserver: PaymentObserving,
    timeSpentRecorder: SourceApplicationTracking & TimeSpentRecording,
    appEventsStateStore: AppEventsStatePersisting,
    eventDeactivationParameterProcessor: AppEventsParameterProcessing,
    restrictiveDataFilterParameterProcessor: AppEventsParameterProcessing,
    atePublisherFactory: ATEPublisherCreating,
    appEventsStateProvider: AppEventsStateProviding,
    advertiserIDProvider: AdvertiserIDProviding,
    userDataStore: UserDataPersisting,
    // swiftlint:disable:next line_length
    appEventsUtility: AppEventDropDetermining & AppEventParametersExtracting & AppEventsUtilityProtocol & LoggingNotifying,
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
    onDeviceMLModelManager modelManager: EventProcessing,
    metadataIndexer: MetadataIndexing,
    skAdNetworkReporter: AppEventsReporter?,
    codelessIndexer: CodelessIndexing.Type,
    swizzler: Swizzling.Type,
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
