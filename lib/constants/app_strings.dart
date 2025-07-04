import 'dart:convert';

import 'package:fuodz/services/local_storage.service.dart';

class AppStrings {
  //
  static String get appName => env('app_name');
  static String get companyName => env('company_name');
  static String get googleMapApiKey => env('google_maps_key');
  static bool get enableChat => env('enableChat') == "1";
  static bool get partnersCanRegister =>
      ["1", 1].contains(env('partnersCanRegister'));
  static String get countryCode => env('country_code');
  static String get fcmApiKey => env('fcm_key');
  static String get currencySymbol => env('currency');

  //
  static String get otpGateway => env('otpGateway') ?? "none";
  static bool get isFirebaseOtp => otpGateway.toLowerCase() == "firebase";
  static bool get isCustomOtp =>
      !["none", "firebase"].contains(otpGateway.toLowerCase());
  //UI Configures
  static dynamic get uiConfig {
    return env('ui') ?? null;
  }

  static bool get qrcodeLogin => env('auth')['qrcodeLogin'];
  static bool get useWebsocketAssignment {
    return (env('useWebsocketAssignment') ?? false);
  }

  //DONT'T TOUCH
  static const String notificationChannel = "high_importance_channel";

  //START DON'T TOUNCH
  //for app usage
  static String firstTimeOnApp = "first_time";
  static String authenticated = "authenticated";
  static String userAuthToken = "auth_token";
  static String userKey = "user";
  static String vendorKey = "vendor";
  static String appLocale = "locale";
  static String notificationsKey = "notifications";
  static String appCurrency = "currency";
  static String appColors = "colors";
  static String appRemoteSettings = "appRemoteSettings";
  static String newOrderNotificationChannelKey = "new_order_channel";
  static String newOrderNotificationSoundSource = "resource://raw/alert_new";
  //END DON'T TOUNCH

  //
  //Change to your app store id
  static String appStoreId = "";

  //
  //saving
  static Future<bool> saveAppSettingsToLocalStorage(String colorsMap) async {
    return await LocalStorageService.prefs!.setString(
      AppStrings.appRemoteSettings,
      colorsMap,
    );
  }

  static dynamic appSettingsObject;
  static Future<void> getAppSettingsFromLocalStorage() async {
    appSettingsObject = LocalStorageService.prefs!.getString(
      AppStrings.appRemoteSettings,
    );
    if (appSettingsObject != null) {
      appSettingsObject = jsonDecode(appSettingsObject);
    }
  }

  static dynamic env(String ref) {
    //
    getAppSettingsFromLocalStorage();
    //
    return appSettingsObject != null ? appSettingsObject[ref] : "";
  }
}
