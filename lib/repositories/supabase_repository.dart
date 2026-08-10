import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_role.dart';
import '../models/booking_type.dart';
import '../models/card_outcome.dart';
import '../models/database/activity_record.dart';
import '../models/database/admin_stats.dart';
import '../models/database/booking_record.dart';
import '../models/database/game_settings.dart';
import '../models/database/leaderboard_entry.dart';
import '../models/database/pending_draw_record.dart';
import '../models/database/saved_special_card.dart';
import '../models/database/user_profile.dart';

class SupabaseRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  bool get hasSession => _client.auth.currentSession != null;

  static String emailForUsername(String username) {
    final String clean = username
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return '$clean@nesting.local';
  }

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: emailForUsername(username),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserProfile> getCurrentProfile() async {
    final dynamic data = await _client.rpc('get_my_profile');
    final List<dynamic> rows = data as List<dynamic>;
    if (rows.isEmpty) {
      throw AuthException('Your account profile is missing.');
    }
    return UserProfile.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<List<UserProfile>> getUsers() async {
    final List<dynamic> data = await _client
        .from('profiles')
        .select('id, username, display_name, role, is_active')
        .order('display_name');
    return data
        .map((dynamic row) => UserProfile.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String displayName,
    required AppRole role,
  }) async {
    final FunctionResponse response = await _client.functions.invoke(
      'create-user',
      body: <String, dynamic>{
        'username': username.trim(),
        'password': password,
        'displayName': displayName.trim(),
        'role': role.name,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw Exception('Could not create user: ${response.data}');
    }
  }

  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    await _client.rpc(
      'admin_set_user_active',
      params: <String, dynamic>{
        'p_user_id': userId,
        'p_is_active': isActive,
      },
    );
  }

  Future<void> updateUserCredentials({
    required String userId,
    String? username,
    String? password,
  }) async {
    final FunctionResponse response = await _client.functions.invoke(
      'update-user',
      body: <String, dynamic>{
        'userId': userId,
        if (username != null) 'username': username.trim(),
        if (password != null) 'password': password,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw Exception('Could not update user: ${response.data}');
    }
  }

  Future<List<BookingRecord>> getMyBookings() async {
    final String? userId = currentUser?.id;
    if (userId == null) return <BookingRecord>[];
    final List<dynamic> data = await _client
        .from('bookings')
        .select('id, agent_id, job_url, job_id, booking_type, status, submitted_at, rejection_reason, profiles!bookings_agent_id_fkey(username, display_name)')
        .eq('agent_id', userId)
        .order('submitted_at', ascending: false);
    return data
        .map((dynamic row) => BookingRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingRecord>> getPendingBookings() async {
    final List<dynamic> data = await _client
        .from('bookings')
        .select('id, agent_id, job_url, job_id, booking_type, status, submitted_at, rejection_reason, profiles!bookings_agent_id_fkey(username, display_name)')
        .eq('status', 'pending')
        .order('submitted_at');
    return data
        .map((dynamic row) => BookingRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitBooking({
    required String jobUrl,
    required BookingType bookingType,
  }) async {
    await _client.rpc(
      'submit_booking',
      params: <String, dynamic>{
        'p_job_url': jobUrl.trim(),
        'p_booking_type': bookingType.databaseValue,
      },
    );
  }

  Future<void> reviewBooking({
    required String bookingId,
    required bool approve,
    required BookingType correctedType,
    String? rejectionReason,
  }) async {
    await _client.rpc(
      'review_booking',
      params: <String, dynamic>{
        'p_booking_id': bookingId,
        'p_approve': approve,
        'p_corrected_type': correctedType.databaseValue,
        'p_rejection_reason': rejectionReason,
      },
    );
  }

  Future<List<PendingDrawRecord>> getMyPendingDraws() async {
    final String? userId = currentUser?.id;
    if (userId == null) return <PendingDrawRecord>[];

    // Commit stale-draw cleanup first, then only return still-valid draws.
    await _client.rpc('expire_my_pending_draws');
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final List<dynamic> data = await _client
        .from('pending_draws')
        .select('id, booking_type, created_at, expires_at')
        .eq('agent_id', userId)
        .eq('status', 'pending')
        .gt('expires_at', nowIso)
        .order('created_at');
    return data
        .map((dynamic row) => PendingDrawRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<DrawResult> drawCard(String pendingDrawId) async {
    final dynamic data = await _client.rpc(
      'draw_card',
      params: <String, dynamic>{'p_pending_draw_id': pendingDrawId},
    );
    return DrawResult.fromJson((data as List<dynamic>).first as Map<String, dynamic>);
  }

  Future<DrawResult> resolveEvenCard({
    required String cardDrawId,
    required bool gamble,
  }) async {
    final dynamic data = await _client.rpc(
      'resolve_even_card',
      params: <String, dynamic>{
        'p_card_draw_id': cardDrawId,
        'p_gamble': gamble,
      },
    );
    return DrawResult.fromJson((data as List<dynamic>).first as Map<String, dynamic>);
  }

  Future<String> saveSpecialCard({
    required String cardDrawId,
    required bool replaceExisting,
  }) async {
    final dynamic data = await _client.rpc(
      'save_special_card',
      params: <String, dynamic>{
        'p_card_draw_id': cardDrawId,
        'p_replace_existing': replaceExisting,
      },
    );
    return data as String;
  }

  Future<List<SavedSpecialCard>> getMySavedSpecialCards() async {
    final String? userId = currentUser?.id;
    if (userId == null) return <SavedSpecialCard>[];
    final List<dynamic> data = await _client
        .from('saved_special_cards')
        .select('id, card_draw_id, card_code, metadata, bookings_remaining, created_at')
        .eq('owner_id', userId)
        .eq('status', 'active')
        .order('created_at');
    return data
        .map((dynamic row) => SavedSpecialCard.fromJson(row as Map<String, dynamic>))
        .toList();
  }


  Future<DrawResult?> getMyAwaitingSpecialDraw() async {
    final String? userId = currentUser?.id;
    if (userId == null) return null;
    final List<dynamic> data = await _client
        .from('card_draws')
        .select('id, title, description, tone, points_delta, card_number, can_gamble')
        .eq('agent_id', userId)
        .eq('status', 'awaiting_storage')
        .eq('is_special', true)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return null;
    final Map<String, dynamic> row = data.first as Map<String, dynamic>;
    return DrawResult.fromJson(<String, dynamic>{
      'card_draw_id': row['id'],
      'title': row['title'],
      'description': row['description'],
      'tone': row['tone'],
      'points': row['points_delta'],
      'number': row['card_number'],
      'can_gamble': row['can_gamble'],
    });
  }

  Future<int> getMyShieldCharges() async {
    final dynamic data = await _client.rpc('get_my_shield_charges');
    return (data as num?)?.toInt() ?? 0;
  }

  Future<SpecialCardUseResult> useSpecialCard({
    required String savedCardId,
    String? targetId,
  }) async {
    final dynamic data = await _client.rpc(
      'use_special_card',
      params: <String, dynamic>{
        'p_saved_card_id': savedCardId,
        'p_target_id': targetId,
      },
    );
    final List<dynamic> rows = data as List<dynamic>;
    if (rows.isEmpty) {
      throw Exception('The special-card action returned no result.');
    }
    return SpecialCardUseResult.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<void> manualGrantDraw({
    required String agentId,
    required BookingType bookingType,
    required String reason,
  }) async {
    await _client.rpc(
      'manual_grant_draw',
      params: <String, dynamic>{
        'p_agent_id': agentId,
        'p_booking_type': bookingType.databaseValue,
        'p_reason': reason,
      },
    );
  }

  Future<void> adjustPoints({
    required String agentId,
    required int amount,
    required String reason,
  }) async {
    await _client.rpc(
      'admin_adjust_points',
      params: <String, dynamic>{
        'p_agent_id': agentId,
        'p_amount': amount,
        'p_reason': reason,
      },
    );
  }

  Future<List<ActivityRecord>> getActivity() async {
    final List<dynamic> data = await _client
        .from('activity_events')
        .select(
          'id, event_type, message, metadata, created_at, '
          'actor:profiles!activity_events_actor_id_fkey(username, display_name)',
        )
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(100);
    return data
        .map((dynamic row) => ActivityRecord.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final List<dynamic> data = await _client
        .from('leaderboard')
        .select('user_id, username, display_name, score, title, rank')
        .order('rank');
    return data
        .map((dynamic row) => LeaderboardEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStats> getAdminStats() async {
    final dynamic data = await _client.rpc('get_admin_stats');
    final List<dynamic> rows = data as List<dynamic>;
    return rows.isEmpty
        ? const AdminStats()
        : AdminStats.fromJson(rows.first as Map<String, dynamic>);
  }

  Future<int> getAdminPendingDrawCount() async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final List<dynamic> data = await _client
        .from('pending_draws')
        .select('id')
        .eq('status', 'pending')
        .gt('expires_at', nowIso);
    return data.length;
  }

  Future<GameSettings?> getGameSettings() async {
    final List<dynamic> data = await _client
        .from('game_settings')
        .select('*')
        .limit(1);
    if (data.isEmpty) return null;
    return GameSettings.fromJson(data.first as Map<String, dynamic>);
  }

  Future<void> updateGameSettings(GameSettings settings) async {
    await _client
        .from('game_settings')
        .update(settings.toUpdateJson())
        .eq('competition_id', settings.competitionId);
  }

  Future<List<Map<String, dynamic>>> getAuditHistory() async {
    final List<dynamic> data = await _client
        .from('audit_logs')
        .select('id, action, entity_type, entity_id, details, created_at, profiles!audit_logs_actor_id_fkey(username, display_name)')
        .order('created_at', ascending: false)
        .limit(100);
    return data.cast<Map<String, dynamic>>();
  }
}

class SpecialCardUseResult {
  const SpecialCardUseResult({
    required this.message,
    required this.shieldBlocked,
  });

  final String message;
  final bool shieldBlocked;

  factory SpecialCardUseResult.fromJson(Map<String, dynamic> json) {
    return SpecialCardUseResult(
      message: (json['message'] as String?) ?? 'Special card used.',
      shieldBlocked: (json['shield_blocked'] as bool?) ?? false,
    );
  }
}

class DrawResult {
  const DrawResult({
    required this.cardDrawId,
    required this.outcome,
  });

  final String cardDrawId;
  final CardOutcome outcome;

  factory DrawResult.fromJson(Map<String, dynamic> json) {
    final String toneValue = (json['tone'] as String?) ?? 'neutral';
    final CardTone tone;
    switch (toneValue) {
      case 'positive':
        tone = CardTone.positive;
        break;
      case 'negative':
        tone = CardTone.negative;
        break;
      case 'special':
        tone = CardTone.special;
        break;
      default:
        tone = CardTone.neutral;
        break;
    }

    return DrawResult(
      cardDrawId: json['card_draw_id'] as String,
      outcome: CardOutcome(
        title: (json['title'] as String?) ?? 'Card',
        description: (json['description'] as String?) ?? '',
        tone: tone,
        points: (json['points'] as num?)?.toInt() ?? 0,
        number: (json['number'] as num?)?.toInt(),
        canGamble: (json['can_gamble'] as bool?) ?? false,
      ),
    );
  }
}
