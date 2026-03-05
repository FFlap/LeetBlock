import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../models/leetcode_stats.dart';
import '../models/problem.dart';
import '../models/problem_list.dart';
import '../services/installed_apps_gateway.dart';
import '../services/leetcode_service.dart';
import '../services/storage_service.dart';
import '../services/platform_service.dart';

class LeetBlockProvider extends ChangeNotifier with WidgetsBindingObserver {
  final LeetCodeService _leetCodeService;
  final StorageService _storageService;
  final InstalledAppsGateway _installedAppsGateway;
  final DateTime Function() _now;
  final Random _random;

  LeetBlockProvider({
    LeetCodeService? leetCodeService,
    StorageService? storageService,
    InstalledAppsGateway? installedAppsGateway,
    DateTime Function()? now,
    Random? random,
  }) : _leetCodeService = leetCodeService ?? LeetCodeService(),
       _storageService = storageService ?? StorageService(),
       _installedAppsGateway =
           installedAppsGateway ?? const DefaultInstalledAppsGateway(),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  String _username = '';
  int _dailyQuota = 1;
  String _blockMessage = 'LOCK IN';
  bool _strictMode = false;
  bool _penaltyEnabled = false;
  int _penaltyThreshold = 30;
  int _penaltyIncrement = 1;
  LeetCodeStats? _currentStats;
  DailyProgress? _dailyProgress;
  List<BlockedAppInfo> _allApps = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _observerRegistered = false;
  bool _isSetupComplete = false;
  String? _error;
  Map<String, dynamic>? _detailedStats;
  int _currentStreak = 0;
  int _totalBlockedTime = 0;
  Map<String, bool> _completionHistory = {};

  // Getters
  String get username => _username;
  int get dailyQuota => _dailyQuota;
  String get blockMessage => _blockMessage;
  bool get strictMode => _strictMode;
  bool get penaltyEnabled => _penaltyEnabled;
  int get penaltyThreshold => _penaltyThreshold;
  int get penaltyIncrement => _penaltyIncrement;
  LeetCodeStats? get currentStats => _currentStats;
  DailyProgress? get dailyProgress => _dailyProgress;
  List<BlockedAppInfo> get allApps => _allApps;
  List<BlockedAppInfo> get blockedApps =>
      _allApps.where((app) => app.isBlocked).toList();
  bool get isLoading => _isLoading;
  bool get isSetupComplete => _isSetupComplete;
  String? get error => _error;
  Map<String, dynamic>? get detailedStats => _detailedStats;
  int get currentStreak => _currentStreak;
  int get totalBlockedTime => _totalBlockedTime;
  Map<String, bool> get completionHistory => _completionHistory;
  Map<String, int> get screenTimeHistory {
    _requireInitialized('screenTimeHistory');
    return _storageService.getDailyScreenTimeHistory();
  }

  Map<String, Map<String, int>> get appUsageHistory {
    _requireInitialized('appUsageHistory');
    return _storageService.getDailyAppUsageHistory();
  }

  LeetCodeService get leetcodeService => _leetCodeService;

  // Async methods to reload SharedPreferences before fetching (for native updates)
  Future<Map<String, int>> getScreenTimeHistoryFresh() async {
    await _storageService.reload();
    return _storageService.getDailyScreenTimeHistory();
  }

  Future<Map<String, Map<String, int>>> getAppUsageHistoryFresh() async {
    await _storageService.reload();
    return _storageService.getDailyAppUsageHistory();
  }

  bool get isQuotaMet => _dailyProgress?.isQuotaMet ?? false;
  bool get isBaseQuotaMet => _dailyProgress?.isBaseQuotaMet ?? false;
  int get questionsCompletedToday =>
      _dailyProgress?.questionsCompletedToday ?? 0;
  int get quotaPenalty => _dailyProgress?.quotaPenalty ?? 0;
  int get effectiveQuota => _dailyQuota + quotaPenalty;
  int get questionsRemaining =>
      (effectiveQuota - questionsCompletedToday).clamp(0, effectiveQuota);
  int get manualOffset => _dailyProgress?.manualOffset ?? 0;

  void _requireInitialized(String propertyName) {
    if (_isInitialized) {
      return;
    }
    throw StateError(
      'LeetBlockProvider is not initialized. Call init() before accessing '
      '$propertyName.',
    );
  }

  /// Initialize the provider
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    await _storageService.init();
    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }
    await _loadSavedData();
    _isInitialized = true;

    // Cache default lists for native code to read
    await _cacheDefaultLists();

    // Fetch fresh stats from LeetCode on app startup
    if (_username.isNotEmpty) {
      await fetchStats();
    }
  }

  Future<void> _cacheDefaultLists() async {
    final defaultLists = {
      'blind75': DefaultProblemLists.blind75.toJson(),
      'neetcode250': DefaultProblemLists.neetcode250.toJson(),
    };
    await _storageService.cacheDefaultLists(defaultLists);
  }

  @override
  void dispose() {
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    _isInitialized = false;
    _leetCodeService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    // Reload daily progress to catch background updates (e.g. penalty)
    await _storageService.reload();
    final savedProgress = _storageService.getDailyProgress();
    if (savedProgress != null) {
      _dailyProgress = savedProgress;
      _totalBlockedTime = _storageService.getTotalBlockedTime();
      await _checkNewDay();
      notifyListeners();
    }
  }

  Future<void> _loadSavedData() async {
    // Reload storage to ensure we have the latest data
    await _storageService.reload();

    _username = _storageService.getUsername() ?? '';
    _dailyQuota = _storageService.getDailyQuota();
    _blockMessage = _storageService.getBlockMessage();
    _strictMode = _storageService.getStrictMode();
    _penaltyEnabled = _storageService.getPenaltyEnabled();
    _penaltyThreshold = _storageService.getPenaltyThreshold();
    _penaltyIncrement = _storageService.getPenaltyIncrement();
    _currentStats = _storageService.getLastStats();
    _dailyProgress = _storageService.getDailyProgress();
    _totalBlockedTime = _storageService.getTotalBlockedTime();
    _isSetupComplete = _storageService.isSetupComplete();
    _completionHistory = _storageService.getDailyCompletionHistory();

    // Load blocked apps
    final savedBlockedApps = _storageService.getBlockedApps();
    if (savedBlockedApps.isNotEmpty) {
      _allApps = savedBlockedApps;
    }

    // Check if it's a new day
    await _checkNewDay();

    notifyListeners();
  }

  Future<void> _checkNewDay() async {
    if (_dailyProgress == null) {
      return;
    }

    final now = _now();
    final progressDate = _dailyProgress!.date;

    if (now.year != progressDate.year ||
        now.month != progressDate.month ||
        now.day != progressDate.day) {
      // It's a new day, reset progress
      _dailyProgress = DailyProgress.newDay(
        _dailyQuota,
        _currentStats?.totalSolved ?? 0,
        date: now,
      );
      await _storageService.saveDailyProgress(_dailyProgress!);
      await _updateHistory();
    }
  }

  /// Validate and save username
  Future<bool> validateAndSaveUsername(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final (isValid, errorMessage) = await _leetCodeService.validateUsername(
        username,
      );

      if (isValid) {
        _username = username;
        await _storageService.saveUsername(username);

        // Fetch initial stats
        await fetchStats();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = errorMessage ?? 'Username not found on LeetCode';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to validate username: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch latest stats from LeetCode
  Future<void> fetchStats() async {
    if (_username.isEmpty) return;

    await _checkNewDay();

    // Check if we need to fetch regardless of quota status
    // (e.g., if difficulty totals are missing/zero)
    final needsTotalsUpdate = (_currentStats?.totalEasy ?? 0) == 0;

    // Don't fetch if quota is already met for the day, UNLESS we need the totals
    if ((_dailyProgress?.isQuotaMet ?? false) && !needsTotalsUpdate) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _leetCodeService.fetchUserStats(_username);

      if (stats != null) {
        _currentStats = stats;
        await _storageService.saveLastStats(stats);

        // Update daily progress using today's accepted submissions
        await _updateDailyProgress(stats.recentSubmissions);
      }
    } catch (e) {
      _error = 'Failed to fetch stats: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetches detailed stats from LeetCode and syncs solved problems to all problem lists
  Future<void> fetchAndSyncProblemLists() async {
    try {
      final result = await _leetCodeService.fetchDetailedStats(_username);
      if (result != null) {
        _detailedStats = result;
        await syncSolvedProblemsToLists();
      }
    } catch (e, st) {
      _error = 'Failed to sync problem lists: $e';
      debugPrint('Failed to sync problem lists: $e\n$st');
      notifyListeners();
    }
  }

  Future<void> _updateDailyProgress(int todaySubmissions) async {
    if (_dailyProgress == null) {
      _dailyProgress = DailyProgress.newDay(
        _dailyQuota,
        _currentStats?.totalSolved ?? 0,
        date: _now(),
      );
    }

    // Apply manual offset to today's submissions from LeetCode API
    // This allows user adjustments to persist through refreshes
    final adjustedCount = (todaySubmissions + _dailyProgress!.manualOffset)
        .clamp(0, 99);

    _dailyProgress = _dailyProgress!.copyWith(
      questionsCompletedToday: adjustedCount,
    );

    await _storageService.saveDailyProgress(_dailyProgress!);
    await _updateHistory();
  }

  /// Set daily quota
  Future<void> setDailyQuota(int quota) async {
    _dailyQuota = quota;
    await _storageService.saveDailyQuota(quota);

    if (_dailyProgress != null) {
      _dailyProgress = _dailyProgress!.copyWith(dailyQuota: quota);
      await _storageService.saveDailyProgress(_dailyProgress!);
      await _updateHistory();
    }

    notifyListeners();
  }

  /// Set block screen message
  Future<void> setBlockMessage(String message) async {
    _blockMessage = message;
    await _storageService.saveBlockMessage(message);
    notifyListeners();
  }

  /// Set strict mode (blocks LeetBlock app itself)
  Future<void> setStrictMode(bool enabled) async {
    _strictMode = enabled;
    await _storageService.saveStrictMode(enabled);
    notifyListeners();
  }

  /// Set penalty enabled
  Future<void> setPenaltyEnabled(bool enabled) async {
    _penaltyEnabled = enabled;
    await _storageService.savePenaltyEnabled(enabled);
    notifyListeners();
  }

  /// Set penalty threshold (minutes)
  Future<void> setPenaltyThreshold(int minutes) async {
    _penaltyThreshold = minutes;
    await _storageService.savePenaltyThreshold(minutes);
    notifyListeners();
  }

  /// Set penalty increment (questions)
  Future<void> setPenaltyIncrement(int amount) async {
    _penaltyIncrement = amount;
    await _storageService.savePenaltyIncrement(amount);
    notifyListeners();
  }

  /// Adjust daily completed count (increment or decrement)
  /// This updates the manual offset, which persists through refreshes
  Future<void> adjustCompletedCount(int delta) async {
    if (_dailyProgress == null) {
      _dailyProgress = DailyProgress.newDay(
        _dailyQuota,
        _currentStats?.totalSolved ?? 0,
        date: _now(),
      );
    }

    // Update the manual offset
    final newOffset = _dailyProgress!.manualOffset + delta;
    final newCount = (questionsCompletedToday + delta).clamp(0, 99);

    _dailyProgress = _dailyProgress!.copyWith(
      questionsCompletedToday: newCount,
      manualOffset: newOffset,
    );

    await _storageService.saveDailyProgress(_dailyProgress!);
    await _updateHistory();
    notifyListeners();
  }

  /// Reset manual offset (clears any manual adjustments)
  Future<void> resetManualOffset() async {
    if (_dailyProgress != null) {
      // Calculate the original count without manual offset
      final currentOffset = _dailyProgress!.manualOffset;
      final originalCount = (_dailyProgress!.questionsCompletedToday -
              currentOffset)
          .clamp(0, 99);

      _dailyProgress = _dailyProgress!.copyWith(
        questionsCompletedToday: originalCount,
        manualOffset: 0,
      );
      await _storageService.saveDailyProgress(_dailyProgress!);
      await _updateHistory();
      notifyListeners();
    }
  }

  /// Load installed apps
  Future<void> loadInstalledApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      // `includeSystemApps: false` excludes system apps at the plugin level.
      final apps = await _installedAppsGateway.getInstalledApps(
        includeSystemApps: false,
        withIcons: true,
      );

      final blockedPackages = _storageService.getBlockedPackageNames();

      // Popular apps to KEEP (whitelist approach)
      final keepPackages = {
        // Google apps
        'com.google.android.youtube',
        'com.google.android.apps.youtube.music',
        'com.google.android.apps.photos',
        'com.google.android.apps.maps',
        'com.google.android.apps.docs',
        'com.google.android.apps.messaging',
        'com.google.android.gm', // Gmail
        'com.google.android.calendar',
        'com.google.android.keep',
        'com.google.android.apps.tachyon', // Google Meet
        'com.google.android.videos', // Google TV
        'com.google.android.apps.fitness',
        'com.google.android.apps.chromecast.app', // Google Home
        // Social Media
        'com.facebook.katana', // Facebook
        'com.facebook.lite',
        'com.facebook.orca', // Messenger
        'com.facebook.mlite', // Messenger Lite
        'com.instagram.android',
        'com.twitter.android', // X (Twitter)
        'com.snapchat.android',
        'com.whatsapp',
        'com.zhiliaoapp.musically', // TikTok
        'com.ss.android.ugc.trill', // TikTok (alternate)
        'com.linkedin.android',
        'com.pinterest',
        'com.reddit.frontpage',
        'org.telegram.messenger',
        'com.discord',
        'com.tumblr',
        'com.viber.voip',
        'jp.naver.line.android', // LINE
        'com.tencent.mm', // WeChat
        // Streaming
        'com.netflix.mediaclient',
        'com.amazon.avod.thirdpartyclient', // Prime Video
        'com.hulu.plus',
        'com.disney.disneyplus',
        'com.hbo.hbonow', // HBO Max
        'com.crunchyroll.crunchyroid',
        'com.spotify.music',
        'com.apple.android.music', // Apple Music
        'com.pandora.android',
        'com.soundcloud.android',
        'tv.twitch.android.app',
        // Gaming
        'com.supercell.clashofclans',
        'com.supercell.clashroyale',
        'com.supercell.brawlstars',
        'com.mojang.minecraftpe',
        'com.roblox.client',
        'com.activision.callofduty.shooter',
        'com.pubg.imobile',
        'com.tencent.ig', // PUBG Mobile
        'com.epicgames.fortnite',
        'com.kiloo.subwaysurf',
        'com.king.candycrushsaga',
      };

      _allApps =
          apps
              .where((app) {
                final pkg = app.packageName.toLowerCase();
                final name = app.name.toLowerCase();

                // Always keep whitelisted apps
                if (keepPackages.contains(app.packageName)) return true;

                // STRICT: App name must look like a real app name
                // Reject if name contains system-like words
                final systemWords = [
                  'carrier',
                  'logging',
                  'monitor',
                  'service',
                  'provider',
                  'framework',
                  'system',
                  'overlay',
                  'stub',
                  'proxy',
                  'test',
                  'diagnostic',
                  'config',
                  'setup',
                  'updater',
                  'installer',
                  'backup',
                  'receiver',
                  'permission',
                  'accessibility',
                  'keyboard',
                  'launcher',
                  'core',
                  'component',
                  'trigger',
                  'support',
                  'lib',
                  'apn',
                  'oem',
                  'vendor',
                  'handler',
                  'helper',
                  'util',
                  'module',
                  'plugin',
                  'extension',
                  'daemon',
                  'agent',
                  'bridge',
                  'sync',
                  'resource',
                  'asset',
                  'cache',
                  'storage',
                  'media',
                  'codec',
                  'decoder',
                  'encoder',
                  'driver',
                  'hal',
                  'hidl',
                  'aidl',
                  'binder',
                  'process',
                  'runtime',
                  'dalvik',
                  'art',
                  'zygote',
                  'init',
                  'boot',
                  'recovery',
                  'fastboot',
                  'bootloader',
                  'partition',
                  'filesystem',
                  'mount',
                  'fuse',
                  'network',
                  'connectivity',
                  'telephony',
                  'radio',
                  'modem',
                  'ril',
                  'sim',
                  'esim',
                  'euicc',
                  'ims',
                  'volte',
                  'wifi',
                  'bluetooth',
                  'nfc',
                  'gps',
                  'sensor',
                  'gyro',
                  'accelerometer',
                  'compass',
                  'barometer',
                  'proximity',
                  'fingerprint',
                  'biometric',
                  'face',
                  'iris',
                  'secure',
                  'crypto',
                  'key',
                  'certificate',
                  'trust',
                  'attestation',
                  'safetynet',
                  'integrity',
                  'maincomponent',
                  'main component',
                  'subcomponent',
                  'sms',
                  'mms',
                  'directed',
                  'rcs',
                ];

                for (final word in systemWords) {
                  if (name.contains(word)) return false;
                }

                // Reject if name looks like a package name
                if (name.startsWith('com.')) return false;
                if (name.startsWith('org.')) return false;
                if (name.startsWith('net.')) return false;
                if (name.contains('.android.')) return false;
                if (name.contains('.google.')) return false;

                // Reject only single-character generic names (but allow whitelisted apps)
                if (name.length <= 1 && !keepPackages.contains(app.packageName))
                  return false;

                // Reject all-uppercase long tokens with no spaces (system component style)
                final lettersOnly = name.replaceAll(RegExp(r'[^A-Za-z]'), '');
                final upperCount =
                    lettersOnly.replaceAll(RegExp(r'[^A-Z]'), '').length;
                if (!name.contains(' ') &&
                    lettersOnly.length >= 8 &&
                    upperCount == lettersOnly.length) {
                  return false;
                }

                // STRICT: Package must be from app store (common patterns)
                // Only allow packages that look like real apps

                // Block all system package prefixes
                final blockedPrefixes = [
                  'com.android.',
                  'com.google.android.',
                  'android.',
                  'vendor.',
                  'com.qualcomm.',
                  'com.qti.',
                  'com.samsung.',
                  'com.sec.',
                  'com.huawei.',
                  'com.oppo.',
                  'com.vivo.',
                  'com.xiaomi.',
                  'com.miui.',
                  'com.oneplus.',
                  'com.coloros.',
                  'com.motorola.',
                  'com.lge.',
                  'com.asus.',
                  'com.sony.',
                  'jp.co.sharp.',
                  'com.mediatek.',
                  'com.spreadtrum.',
                  'com.unisoc.',
                  'com.realme.',
                  'com.transsion.',
                  'com.infinix.',
                  'com.tecno.',
                  'com.itel.',
                  'org.codeaurora.',
                  'com.oem.',
                  'com.sonymobile.',
                  'com.htc.',
                  'com.lenovo.',
                ];

                for (final prefix in blockedPrefixes) {
                  if (pkg.startsWith(prefix) &&
                      !keepPackages.contains(app.packageName)) {
                    return false;
                  }
                }

                // Block packages containing system keywords
                final blockedKeywords = [
                  'overlay',
                  'proxy',
                  'stub',
                  'provider',
                  'receiver',
                  'extension',
                  'permission',
                  'installer',
                  'wellbeing',
                  'setupwizard',
                  'deviceconfig',
                  'emulator',
                  'printservice',
                  'captiveportal',
                  'hotword',
                  'systemui',
                  'cbrs',
                  'networkmonitor',
                  'carrier',
                  'logging',
                  'dialer',
                  'telecom',
                  'telephony',
                  'euicc',
                  'simapp',
                  'stk',
                  'gms',
                  'gsf',
                  'trichrome',
                  'webview',
                  'inputmethod',
                  'keyboard',
                  'launcher',
                  'wallpaper',
                  'theme',
                  'backup',
                  'feedback',
                  'partnersetup',
                  'printspooler',
                  'nfc',
                  'bluetooth',
                  'wifi',
                  'location',
                  'cellbroadcast',
                  'emergency',
                  'safetyhub',
                  'dm',
                  'trigger',
                  'apnlib',
                  'component',
                  'mainline',
                  'apex',
                  'module',
                  'sms',
                  'mms',
                  'directed',
                  'rcs',
                  'messaging',
                ];

                for (final keyword in blockedKeywords) {
                  if (pkg.contains(keyword)) return false;
                }

                // Filter out our own app
                if (pkg == 'com.leetblock.leet_block') return false;

                return true;
              })
              .map((app) {
                return BlockedAppInfo(
                  packageName: app.packageName,
                  appName: app.name,
                  icon: app.icon,
                  isBlocked: blockedPackages.contains(app.packageName),
                );
              })
              .toList();

      // Sort alphabetically
      _allApps.sort(
        (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
      );
    } catch (e) {
      _error = 'Failed to load apps: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggle app blocking
  Future<void> toggleAppBlocking(String packageName) async {
    final index = _allApps.indexWhere((app) => app.packageName == packageName);
    if (index == -1) return;

    _allApps[index] = _allApps[index].copyWith(
      isBlocked: !_allApps[index].isBlocked,
    );

    await _storageService.saveBlockedApps(_allApps);
    notifyListeners();
  }

  /// Check if a specific app is blocked
  bool isAppBlocked(String packageName) {
    return _allApps.any(
      (app) => app.packageName == packageName && app.isBlocked,
    );
  }

  /// Check if user should be blocked from using an app
  Future<bool> shouldBlockApp(String packageName) async {
    if (!isAppBlocked(packageName)) return false;

    // Refresh stats if quota not met
    if (!isQuotaMet) {
      await fetchStats();
    }

    return !isQuotaMet;
  }

  /// Complete setup
  Future<void> completeSetup() async {
    _isSetupComplete = true;

    // Initialize daily progress
    _dailyProgress = DailyProgress.newDay(
      _dailyQuota,
      _currentStats?.totalSolved ?? 0,
      date: _now(),
    );

    await _storageService.setSetupComplete(true);
    await _storageService.saveDailyProgress(_dailyProgress!);
    await _updateHistory();
    notifyListeners();
  }

  /// Reset the app
  Future<void> reset() async {
    try {
      await stopBlockerService();
    } catch (error, stackTrace) {
      debugPrint('Failed to stop blocker service during reset: $error');
      debugPrint('$stackTrace');
    }
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    await _storageService.clearAll();

    _username = '';
    _dailyQuota = 1;
    _blockMessage = 'LOCK IN';
    _strictMode = false;
    _penaltyEnabled = false;
    _penaltyThreshold = 30;
    _penaltyIncrement = 1;
    _currentStats = null;
    _dailyProgress = null;
    _allApps = [];
    _isLoading = false;
    _isInitialized = false;
    _isSetupComplete = false;
    _error = null;
    _detailedStats = null;
    _currentStreak = 0;
    _totalBlockedTime = 0;
    _completionHistory = {};
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if all required permissions are granted
  Future<bool> checkPermissions() async {
    return await PlatformService.hasAllPermissions();
  }

  /// Start the app blocker service
  Future<void> startBlockerService() async {
    await PlatformService.startBlockerService();
  }

  /// Stop the app blocker service
  Future<void> stopBlockerService() async {
    await PlatformService.stopBlockerService();
  }

  /// Open LeetCode in browser
  Future<void> openLeetCode() async {
    await PlatformService.openLeetCode();
  }

  /// Fetch detailed stats for statistics page
  Future<void> fetchDetailedStats() async {
    if (_username.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Reload SharedPreferences to get latest data from native side
      await _storageService.reload();

      // Refresh completion history from storage (may have been updated by another session)
      _completionHistory = _storageService.getDailyCompletionHistory();

      final result = await _leetCodeService.fetchDetailedStats(_username);

      if (result != null) {
        _detailedStats = result;
        _currentStreak = result['streak'] ?? 0;

        // Also update current stats if available
        if (result['stats'] != null) {
          _currentStats = result['stats'] as LeetCodeStats;
          await _storageService.saveLastStats(_currentStats!);
        }
      }
    } catch (e) {
      _error = 'Failed to fetch detailed stats: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Syncs LeetCode solved problems to all problem lists
  Future<void> syncSolvedProblemsToLists() async {
    if (_detailedStats == null) return;

    // Get solved problem titles from LeetCode
    final recentProblems = _detailedStats!['recentProblems'] as List<dynamic>?;
    if (recentProblems == null || recentProblems.isEmpty) return;

    // Extract titles and normalize them
    final solvedTitles =
        recentProblems
            .map((p) => (p['title'] as String?)?.toLowerCase().trim())
            .where((t) => t != null)
            .cast<String>()
            .toSet();

    if (solvedTitles.isEmpty) return;

    // Get all problem lists
    final defaultLists = [
      DefaultProblemLists.blind75,
      DefaultProblemLists.neetcode250,
    ];

    // Load custom lists
    final savedListsJson = _storageService.getProblemLists();
    final customLists =
        savedListsJson
            .map((json) => ProblemList.fromJson(json))
            .where((list) => list.isCustom)
            .toList();

    final allLists = [...defaultLists, ...customLists];

    // Get existing completion status
    final completion = _storageService.getProblemCompletion();
    bool hasChanges = false;

    // Match and mark problems as complete
    for (final list in allLists) {
      for (final category in list.categories.entries) {
        for (final problem in category.value) {
          final problemTitle = problem.title.toLowerCase().trim();
          // Remove "(Premium)" suffix if present for matching
          final cleanTitle = problemTitle.replaceAll(
            RegExp(r'\s*\(premium\)\s*$', caseSensitive: false),
            '',
          );

          if (solvedTitles.contains(cleanTitle) ||
              solvedTitles.contains(problemTitle)) {
            final key = '${list.id}_${problem.id}';
            if (completion[key] != true) {
              completion[key] = true;
              hasChanges = true;
            }
          }
        }
      }
    }

    // Save if there were changes
    if (hasChanges) {
      await _storageService.saveProblemCompletion(completion);
    }
  }

  // Study Preferences
  Map<String, dynamic> get studyPreferences =>
      _storageService.getStudyPreferences();

  Future<void> setStudyList(String? listId) async {
    final prefs = _storageService.getStudyPreferences();
    prefs['activeListId'] = listId;
    await _storageService.saveStudyPreferences(prefs);
    notifyListeners();
  }

  Future<void> setStudyOptions({
    required bool random,
    required bool unsolvedOnly,
    required bool easiestFirst,
    required bool skipPremium,
  }) async {
    final prefs = _storageService.getStudyPreferences();
    prefs['random'] = random;
    prefs['unsolvedOnly'] = unsolvedOnly;
    prefs['easiestFirst'] = easiestFirst;
    prefs['skipPremium'] = skipPremium;
    await _storageService.saveStudyPreferences(prefs);
    notifyListeners();
  }

  /// Gets the URL of the next problem to solve based on study preferences
  /// Returns null if no study list is selected or all problems are completed
  String? getNextProblemUrl() {
    final prefs = _storageService.getStudyPreferences();
    final activeListId = prefs['activeListId'] as String?;
    final random = prefs['random'] as bool? ?? false;
    final unsolvedOnly = prefs['unsolvedOnly'] as bool? ?? true;
    final easiestFirst = prefs['easiestFirst'] as bool? ?? false;
    final skipPremium = prefs['skipPremium'] as bool? ?? true;

    if (activeListId == null) return null;

    // Get the active list
    ProblemList? activeList;
    if (activeListId == 'blind75') {
      activeList = DefaultProblemLists.blind75;
    } else if (activeListId == 'neetcode250') {
      activeList = DefaultProblemLists.neetcode250;
    } else {
      // Check custom lists
      final savedListsJson = _storageService.getProblemLists();
      for (final json in savedListsJson) {
        final list = ProblemList.fromJson(json);
        if (list.id == activeListId) {
          activeList = list;
          break;
        }
      }
    }

    if (activeList == null) return null;

    // Get completion status
    final completion = _storageService.getProblemCompletion();

    // Collect all problems
    final allProblems = <Problem>[];
    for (final category in activeList.categories.entries) {
      for (final problem in category.value) {
        allProblems.add(problem);
      }
    }

    if (allProblems.isEmpty) return null;

    // Filter based on unsolvedOnly flag
    var candidateProblems =
        unsolvedOnly
            ? allProblems.where((problem) {
              final key = '${activeList!.id}_${problem.id}';
              return completion[key] != true;
            }).toList()
            : allProblems.toList();

    // Filter out premium problems if skipPremium is enabled
    if (skipPremium) {
      candidateProblems = candidateProblems.where((p) => !p.isPremium).toList();
    }

    if (candidateProblems.isEmpty) return null;

    // Sort by difficulty if easiestFirst is enabled
    if (easiestFirst) {
      candidateProblems.sort((a, b) {
        const order = {'Easy': 0, 'Medium': 1, 'Hard': 2};
        return (order[a.difficulty] ?? 1).compareTo(order[b.difficulty] ?? 1);
      });
    }

    // Select problem based on random flag
    Problem selectedProblem;
    if (random) {
      if (easiestFirst && candidateProblems.isNotEmpty) {
        // Pick random from the easiest difficulty tier
        final lowestDifficulty = candidateProblems.first.difficulty;
        final sameLevel =
            candidateProblems
                .where((p) => p.difficulty == lowestDifficulty)
                .toList();
        selectedProblem = sameLevel[_random.nextInt(sameLevel.length)];
      } else {
        // Pick any random from candidates
        selectedProblem =
            candidateProblems[_random.nextInt(candidateProblems.length)];
      }
    } else {
      // Pick first
      selectedProblem = candidateProblems.first;
    }

    return selectedProblem.url;
  }

  Future<void> _updateHistory() async {
    if (_dailyProgress != null) {
      final date = _dailyProgress!.date;
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      // Use isBaseQuotaMet for weekly goal tracking (ignoring penalty)
      _completionHistory[dateKey] = _dailyProgress!.isBaseQuotaMet;
      await _storageService.saveDailyCompletionHistory(_completionHistory);
    }
  }
}
