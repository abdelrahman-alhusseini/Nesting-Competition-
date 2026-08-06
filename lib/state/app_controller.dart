import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_role.dart';
import '../models/booking_type.dart';
import '../models/card_outcome.dart';
import '../models/database/activity_record.dart';
import '../models/database/admin_stats.dart';
import '../models/database/booking_record.dart';
import '../models/database/leaderboard_entry.dart';
import '../models/database/pending_draw_record.dart';
import '../models/database/saved_special_card.dart';
import '../models/database/user_profile.dart';
import '../models/navigation.dart';
import '../repositories/supabase_repository.dart';
import '../services/audio_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required SupabaseRepository? repository,
    AudioService audioService = const AudioService(),
  })  : _repository = repository,
        _audio = audioService;

  final SupabaseRepository? _repository;
  final AudioService _audio;
  final Random _random = Random();

  bool _initializing = true;
  bool _busy = false;
  bool _refreshing = false;
  Timer? _refreshTimer;
  bool _loggedIn = false;
  AppRole _selectedLoginRole = AppRole.agent;
  AppRole? _role;
  UserProfile? _profile;
  AgentPage _agentPage = AgentPage.dashboard;
  AdminPage _adminPage = AdminPage.dashboard;
  BookingType _adminTestBookingType = BookingType.normal;
  CardOutcome? _currentOutcome;
  String? _currentCardDrawId;
  bool _gamblePending = false;
  bool _specialStoragePending = false;
  String? _lastError;

  List<BookingRecord> _myBookings = <BookingRecord>[];
  List<BookingRecord> _pendingBookings = <BookingRecord>[];
  List<PendingDrawRecord> _pendingDrawRecords = <PendingDrawRecord>[];
  List<ActivityRecord> _activityRecords = <ActivityRecord>[];
  List<LeaderboardEntry> _leaderboard = <LeaderboardEntry>[];
  List<UserProfile> _users = <UserProfile>[];
  List<Map<String, dynamic>> _auditHistory = <Map<String, dynamic>>[];
  SavedSpecialCard? _savedSpecialCard;
  AdminStats _adminStats = const AdminStats();

  bool get databaseConfigured => _repository != null;
  bool get initializing => _initializing;
  bool get busy => _busy;
  bool get loggedIn => _loggedIn;
  AppRole get selectedLoginRole => _selectedLoginRole;
  AppRole? get role => _role;
  String get username => _profile?.displayName ?? _profile?.username ?? '';
  UserProfile? get profile => _profile;
  AgentPage get agentPage => _agentPage;
  AdminPage get adminPage => _adminPage;
  BookingType get adminTestBookingType => _adminTestBookingType;
  CardOutcome? get currentOutcome => _currentOutcome;
  bool get gamblePending => _gamblePending;
  bool get specialStoragePending => _specialStoragePending;
  String? get lastError => _lastError;
  int get agentScore => _profile?.score ?? 0;
  int get pendingDraws => _pendingDrawRecords.length;
  List<String> get activity => _activityRecords
      .map((ActivityRecord item) => item.message)
      .toList(growable: false);
  int get bookingCount =>
      _role == AppRole.admin ? _adminStats.totalBookings : _myBookings.length;
  List<BookingRecord> get myBookings =>
      List<BookingRecord>.unmodifiable(_myBookings);
  List<BookingRecord> get pendingBookings =>
      List<BookingRecord>.unmodifiable(_pendingBookings);
  List<LeaderboardEntry> get leaderboard =>
      List<LeaderboardEntry>.unmodifiable(_leaderboard);
  List<UserProfile> get users => List<UserProfile>.unmodifiable(_users);
  List<Map<String, dynamic>> get auditHistory =>
      List<Map<String, dynamic>>.unmodifiable(_auditHistory);
  SavedSpecialCard? get savedSpecialCard => _savedSpecialCard;
  AdminStats get adminStats => _adminStats;

  Future<void> initialize() async {
    try {
      if (_repository?.hasSession ?? false) {
        await _restoreSession();
      }
    } catch (error) {
      _lastError = _friendlyError(error);
      await _repository?.signOut();
      _clearSessionState();
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  void chooseLoginRole(AppRole role) {
    _selectedLoginRole = role;
    _audio.click();
    notifyListeners();
  }

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    final String cleanUsername = username.trim();
    final SupabaseRepository? repository = _repository;
    if (repository == null) {
      return 'Supabase is not configured yet. Add the project URL and publishable key.';
    }
    if (cleanUsername.isEmpty) return 'Enter a username.';
    if (password.length < 6)
      return 'Password must contain at least 6 characters.';

    _setBusy(true);
    try {
      await repository.signIn(username: cleanUsername, password: password);
      final UserProfile profile = await repository.getCurrentProfile();
      if (!profile.isActive) {
        await repository.signOut();
        return 'This account has been disabled by an administrator.';
      }
      if (profile.role != _selectedLoginRole) {
        await repository.signOut();
        return profile.role == AppRole.admin
            ? 'This is an admin account. Select Admin Login.'
            : 'This is an agent account. Select Agent Login.';
      }

      _profile = profile;
      _role = profile.role;
      _loggedIn = true;
      _agentPage = AgentPage.dashboard;
      _adminPage = AdminPage.dashboard;
      _lastError = null;
      await refreshAll();
      _startAutoRefresh();
      _audio.positive();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _restoreSession() async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return;

    final UserProfile profile = await repository.getCurrentProfile();
    if (!profile.isActive) {
      await repository.signOut();
      return;
    }
    _profile = profile;
    _role = profile.role;
    _selectedLoginRole = profile.role;
    _loggedIn = true;
    await refreshAll();
    _startAutoRefresh();
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await _repository?.signOut();
    } finally {
      _clearSessionState();
      _selectedLoginRole = AppRole.agent;
      _audio.click();
      _setBusy(false);
    }
  }

  void _clearSessionState() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _loggedIn = false;
    _role = null;
    _profile = null;
    _currentOutcome = null;
    _currentCardDrawId = null;
    _gamblePending = false;
    _specialStoragePending = false;
    _myBookings = <BookingRecord>[];
    _pendingBookings = <BookingRecord>[];
    _pendingDrawRecords = <PendingDrawRecord>[];
    _activityRecords = <ActivityRecord>[];
    _leaderboard = <LeaderboardEntry>[];
    _users = <UserProfile>[];
    _auditHistory = <Map<String, dynamic>>[];
    _savedSpecialCard = null;
    _adminStats = const AdminStats();
    notifyListeners();
  }

  Future<void> refreshAll() async {
    final SupabaseRepository? repository = _repository;
    if (repository == null || !_loggedIn || _refreshing) return;
    _refreshing = true;
    try {
      final UserProfile freshProfile = await repository.getCurrentProfile();
      final List<ActivityRecord> activity = await repository.getActivity();
      final List<LeaderboardEntry> leaderboard =
          await repository.getLeaderboard();
      _profile = freshProfile;
      _activityRecords = activity;
      _leaderboard = leaderboard;

      if (_role == AppRole.agent) {
        final List<dynamic> results =
            await Future.wait<dynamic>(<Future<dynamic>>[
          repository.getMyBookings(),
          repository.getMyPendingDraws(),
          repository.getMySavedSpecialCard(),
        ]);
        _myBookings = results[0] as List<BookingRecord>;
        _pendingDrawRecords = results[1] as List<PendingDrawRecord>;
        _savedSpecialCard = results[2] as SavedSpecialCard?;
      } else if (_role == AppRole.admin) {
        final List<dynamic> results =
            await Future.wait<dynamic>(<Future<dynamic>>[
          repository.getPendingBookings(),
          repository.getUsers(),
          repository.getAdminStats(),
          repository.getAuditHistory(),
        ]);
        _pendingBookings = results[0] as List<BookingRecord>;
        _users = results[1] as List<UserProfile>;
        _adminStats = results[2] as AdminStats;
        _auditHistory = results[3] as List<Map<String, dynamic>>;
      }
      _lastError = null;
    } catch (error) {
      _lastError = _friendlyError(error);
    } finally {
      _refreshing = false;
    }
    notifyListeners();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_loggedIn && !_busy) unawaited(refreshAll());
    });
  }

  void openAgentPage(AgentPage page) {
    _agentPage = page;
    _audio.click();
    unawaited(refreshAll());
    notifyListeners();
  }

  void openAdminPage(AdminPage page) {
    _adminPage = page;
    _audio.click();
    unawaited(refreshAll());
    notifyListeners();
  }

  Future<String?> submitBooking(String link, BookingType bookingType) async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return 'Supabase is not configured.';
    _setBusy(true);
    try {
      await repository.submitBooking(jobUrl: link, bookingType: bookingType);
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> reviewBooking({
    required BookingRecord booking,
    required bool approve,
    required BookingType correctedType,
    String? rejectionReason,
  }) async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return 'Supabase is not configured.';
    _setBusy(true);
    try {
      await repository.reviewBooking(
        bookingId: booking.id,
        approve: approve,
        correctedType: correctedType,
        rejectionReason: rejectionReason,
      );
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> createUser({
    required String username,
    required String displayName,
    required String password,
    required AppRole role,
  }) async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return 'Supabase is not configured.';
    if (username.trim().isEmpty) return 'Enter a username.';
    if (password.length < 6)
      return 'Password must contain at least 6 characters.';
    _setBusy(true);
    try {
      await repository.createUser(
        username: username,
        password: password,
        displayName:
            displayName.trim().isEmpty ? username.trim() : displayName.trim(),
        role: role,
      );
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> setUserActive(UserProfile user, bool isActive) async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return 'Supabase is not configured.';
    _setBusy(true);
    try {
      await repository.setUserActive(userId: user.id, isActive: isActive);
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  void setAdminTestBookingType(BookingType type) {
    _adminTestBookingType = type;
    notifyListeners();
  }

  void drawUnlimitedAdminTestCard() {
    _currentOutcome = _generateLocalTestOutcome(_adminTestBookingType);
    _currentCardDrawId = null;
    _gamblePending = _currentOutcome?.canGamble ?? false;
    _specialStoragePending = false;
    _adminPage = AdminPage.cardReveal;
    _audio.flip();
    notifyListeners();
  }

  Future<void> drawAgentCard() async {
    final SupabaseRepository? repository = _repository;
    if (repository == null || _pendingDrawRecords.isEmpty || _busy) return;
    _setBusy(true);
    try {
      final DrawResult result =
          await repository.drawCard(_pendingDrawRecords.first.id);
      _currentOutcome = result.outcome;
      _currentCardDrawId = result.cardDrawId;
      _gamblePending = result.outcome.canGamble;
      _specialStoragePending = result.outcome.isSpecial;
      _agentPage = AgentPage.cardReveal;
      _audio.flip();
      await refreshAll();
    } catch (error) {
      _lastError = _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> keepEvenCardPoint({required bool adminTest}) async {
    final CardOutcome? currentOutcome = _currentOutcome;
    if (!_gamblePending || currentOutcome == null) return;
    if (adminTest) {
      _currentOutcome = CardOutcome(
        title: '+1 Point',
        description: 'You kept the guaranteed point.',
        tone: CardTone.positive,
        points: 1,
        number: currentOutcome.number,
      );
    } else {
      await _resolveEvenCard(gamble: false);
    }
    _gamblePending = false;
    _audio.positive();
    notifyListeners();
  }

  Future<void> gambleEvenCard({required bool adminTest}) async {
    final CardOutcome? currentOutcome = _currentOutcome;
    if (!_gamblePending || currentOutcome == null) return;
    if (adminTest) {
      final bool won = _random.nextBool();
      _currentOutcome = CardOutcome(
        title: won ? '+4 Points' : '-6 Points',
        description: won
            ? 'The 50/50 risk paid off.'
            : 'The 50/50 risk did not go your way.',
        tone: won ? CardTone.positive : CardTone.negative,
        points: won ? 4 : -6,
        number: currentOutcome.number,
      );
      won ? _audio.positive() : _audio.negative();
    } else {
      await _resolveEvenCard(gamble: true);
    }
    _gamblePending = false;
    notifyListeners();
  }

  Future<void> _resolveEvenCard({required bool gamble}) async {
    final SupabaseRepository? repository = _repository;
    final String? cardDrawId = _currentCardDrawId;
    if (repository == null || cardDrawId == null) return;
    _setBusy(true);
    try {
      final DrawResult result = await repository.resolveEvenCard(
        cardDrawId: cardDrawId,
        gamble: gamble,
      );
      _currentOutcome = result.outcome;
      gamble && result.outcome.isNegative
          ? _audio.negative()
          : _audio.positive();
      await refreshAll();
    } catch (error) {
      _lastError = _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> saveCurrentSpecialCard(
      {required bool replaceExisting}) async {
    final SupabaseRepository? repository = _repository;
    final String? cardDrawId = _currentCardDrawId;
    if (repository == null || cardDrawId == null) {
      return 'No special card is waiting to be saved.';
    }
    _setBusy(true);
    try {
      await repository.saveSpecialCard(
        cardDrawId: cardDrawId,
        replaceExisting: replaceExisting,
      );
      _specialStoragePending = false;
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  void finishRevealSound() {
    final CardOutcome? outcome = _currentOutcome;
    if (outcome == null || _gamblePending) return;
    if (outcome.isSpecial) {
      _audio.special();
    } else if (outcome.isNegative) {
      _audio.negative();
    } else {
      _audio.positive();
    }
  }

  void continueAfterAgentReveal() {
    if (_specialStoragePending) return;
    _agentPage = pendingDraws > 0 ? AgentPage.drawCards : AgentPage.dashboard;
    _currentOutcome = null;
    _currentCardDrawId = null;
    _gamblePending = false;
    notifyListeners();
  }

  void returnToAdminTestDraw() {
    _currentOutcome = null;
    _currentCardDrawId = null;
    _gamblePending = false;
    _adminPage = AdminPage.testDraw;
    notifyListeners();
  }

  Future<String?> grantAgentDraw({
    required String agentId,
    required BookingType bookingType,
    required String reason,
  }) async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return 'Supabase is not configured.';
    _setBusy(true);
    try {
      await repository.manualGrantDraw(
        agentId: agentId,
        bookingType: bookingType,
        reason: reason,
      );
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> adjustAgentPoints({
    required String agentId,
    required int amount,
    required String reason,
  }) async {
    final SupabaseRepository? repository = _repository;
    if (repository == null) return 'Supabase is not configured.';
    _setBusy(true);
    try {
      await repository.adjustPoints(
        agentId: agentId,
        amount: amount,
        reason: reason,
      );
      await refreshAll();
      return null;
    } catch (error) {
      return _friendlyError(error);
    } finally {
      _setBusy(false);
    }
  }

  CardOutcome _generateLocalTestOutcome(BookingType bookingType) {
    if (_random.nextDouble() < bookingType.specialChance) {
      return _generateLocalSpecialOutcome(bookingType);
    }

    final int roll = _random.nextInt(100);
    if (roll < 60) {
      final int number = _random.nextInt(10);
      if (number == 7) {
        return const CardOutcome(
          title: 'Lucky 7: +3 Points',
          description: 'Seven awards three points instead of one.',
          tone: CardTone.positive,
          points: 3,
          number: 7,
        );
      }
      if (number.isEven) {
        return CardOutcome(
          title: 'Even Number: $number',
          description: 'Keep +1 or take the 50/50 risk for +4 / -6.',
          tone: CardTone.neutral,
          points: 0,
          number: number,
          canGamble: true,
        );
      }
      return CardOutcome(
        title: 'Number $number: +1 Point',
        description: 'A standard number card.',
        tone: CardTone.positive,
        points: 1,
        number: number,
      );
    }
    if (roll < 72) {
      return const CardOutcome(
        title: '+2 Points',
        description: 'Two points were awarded.',
        tone: CardTone.positive,
        points: 2,
      );
    }
    if (roll < 79) {
      return const CardOutcome(
        title: '+4 Points',
        description: 'Four points were awarded.',
        tone: CardTone.positive,
        points: 4,
      );
    }
    if (roll < 89) {
      return const CardOutcome(
        title: 'Reverse: -1 Point',
        description: 'Reverse removes one point.',
        tone: CardTone.negative,
        points: -1,
      );
    }
    return const CardOutcome(
      title: 'Skip',
      description: 'No points were added or removed.',
      tone: CardTone.neutral,
    );
  }

  CardOutcome _generateLocalSpecialOutcome(BookingType type) {
    final List<CardOutcome> standard = <CardOutcome>[
      const CardOutcome(
        title: 'Move Yourself Up 2 Ranks',
        description: 'Gain exactly enough points to move up two positions.',
        tone: CardTone.special,
      ),
      const CardOutcome(
        title: 'Move Another Player 2 Ranks',
        description: 'Choose a player and move them up or down two positions.',
        tone: CardTone.special,
      ),
      const CardOutcome(
        title: 'Shield',
        description: 'Block the next special-card attack against you.',
        tone: CardTone.special,
      ),
    ];
    final List<CardOutcome> remodeling = <CardOutcome>[
      const CardOutcome(
        title: 'Transfer 5 Points',
        description: 'Take five points from a selected agent.',
        tone: CardTone.special,
        points: 5,
      ),
      const CardOutcome(
        title: 'Rank Swap',
        description: 'Swap with a player up to five ranks above you.',
        tone: CardTone.special,
      ),
      const CardOutcome(
        title: 'Double Promotion',
        description: 'Move yourself up exactly two leaderboard positions.',
        tone: CardTone.special,
      ),
    ];
    final List<CardOutcome> pool =
        type == BookingType.remodelingCrossSell ? remodeling : standard;
    return pool[_random.nextInt(pool.length)];
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _friendlyError(Object error) {
    if (error is AuthException) {
      if (error.message.toLowerCase().contains('invalid login')) {
        return 'Incorrect username or password.';
      }
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
