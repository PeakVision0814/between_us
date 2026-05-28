import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef FetchCurrentCoupleSpaceId = Future<String?> Function();
typedef CreateCoupleSpace = Future<String?> Function();

class CoupleSpaceGuard {
  CoupleSpaceGuard({
    required this._fetchCurrentSpaceId,
    required this._createCoupleSpace,
  });

  factory CoupleSpaceGuard.usingSupabase([SupabaseClient? client]) {
    return CoupleSpaceGuard(
      fetchCurrentSpaceId: () async {
        final supabaseClient = client ?? Supabase.instance.client;
        final response = await supabaseClient
            .from('couple_spaces')
            .select('id')
            .limit(1)
            .maybeSingle();
        return response?['id'] as String?;
      },
      createCoupleSpace: () async {
        final supabaseClient = client ?? Supabase.instance.client;
        final response = await supabaseClient.rpc('create_couple_space');
        return switch (response) {
          final String id when id.isNotEmpty => id,
          final Map<String, dynamic> row => row['id'] as String?,
          final List<dynamic> rows when rows.isNotEmpty =>
            (rows.first as Map<String, dynamic>)['id'] as String?,
          _ => null,
        };
      },
    );
  }

  final FetchCurrentCoupleSpaceId _fetchCurrentSpaceId;
  final CreateCoupleSpace _createCoupleSpace;

  String? _cachedSpaceId;
  Future<String>? _pendingEnsureOperation;

  Future<String?> loadCurrentSpaceId() async {
    final currentId = await _fetchCurrentSpaceId();
    if (currentId != null && currentId.isNotEmpty) {
      _cachedSpaceId = currentId;
    }
    return _cachedSpaceId;
  }

  Future<String> ensureSpaceId() {
    final cachedSpaceId = _cachedSpaceId;
    if (cachedSpaceId != null && cachedSpaceId.isNotEmpty) {
      return Future<String>.value(cachedSpaceId);
    }

    final pendingOperation = _pendingEnsureOperation;
    if (pendingOperation != null) {
      return pendingOperation;
    }

    final operation = _ensureSpaceIdInternal();
    _pendingEnsureOperation = operation;
    return operation.whenComplete(() {
      if (identical(_pendingEnsureOperation, operation)) {
        _pendingEnsureOperation = null;
      }
    });
  }

  Future<String> _ensureSpaceIdInternal() async {
    final existingSpaceId = await loadCurrentSpaceId();
    if (existingSpaceId != null && existingSpaceId.isNotEmpty) {
      return existingSpaceId;
    }

    try {
      final createdSpaceId = await _createCoupleSpace();
      if (createdSpaceId != null && createdSpaceId.isNotEmpty) {
        _cachedSpaceId = createdSpaceId;
        return createdSpaceId;
      }
    } catch (error) {
      debugPrint('[CoupleSpace] create_couple_space failed: $error');
      final refetchedSpaceId = await loadCurrentSpaceId();
      if (refetchedSpaceId != null && refetchedSpaceId.isNotEmpty) {
        return refetchedSpaceId;
      }
      rethrow;
    }

    final refetchedSpaceId = await loadCurrentSpaceId();
    if (refetchedSpaceId != null && refetchedSpaceId.isNotEmpty) {
      return refetchedSpaceId;
    }

    throw StateError('No couple_space_id available after ensureSpaceId');
  }
}
