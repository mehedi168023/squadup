import 'package:flutter/material.dart';

/// A top-level game category shown on Home (e.g. "Free Fire", "Ludo Game").
/// Tapping it opens that category's screen of modes/games.
class GameCategory {
  final String key; // freefire | ludo
  final String title;
  final String subtitle;
  final IconData icon; // tile + watermark glyph
  final String? image; // optional brand image for the tile (e.g. FF logo)
  final List<Color> colors; // card background gradient
  final List<String> modeKeys; // mode keys that count toward its badge

  const GameCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.modeKeys,
    this.image,
  });
}

/// A game mode / game tile ("BR MATCH", "LONE WOLF", "Ludo King", ...).
class GameMode {
  final String key;
  final String title;
  final String image; // asset path (Free Fire art); empty for icon-based tiles
  final IconData icon; // used when [image] is empty (e.g. Ludo)
  final String subtitle;
  final int matchesFound;

  const GameMode({
    required this.key,
    required this.title,
    this.image = '',
    this.icon = Icons.sports_esports,
    this.subtitle = '',
    this.matchesFound = 0,
  });
}

/// One player who joined a match.
class Participant {
  final int slot;
  final String ign; // in-game name
  const Participant({required this.slot, required this.ign});

  factory Participant.fromJson(Map<String, dynamic> j) => Participant(
        slot: (j['slot'] ?? 0) as int,
        ign: (j['ign'] ?? '').toString(),
      );
}

/// A Free Fire match — fields mirror the match JSON in the original binary.
class FfMatch {
  final int id;
  final String title; // "BR Solo Time 👑"
  final String modeKey; // br | cs | lone_wolf | free
  final String modeLabel; // "BR MATCH"
  final DateTime startTime;
  final String status; // active | live | closed
  final String map; // Bermuda
  final String type; // Solo | Duo | Squad
  final String version; // TTP
  final String device; // Android
  final double prize;
  final double perKill;
  final double entryFee;
  final int slotsTaken;
  final int slotsTotal;
  final String rules; // Bangla rules text
  final List<Participant> participants;
  final bool isJoined;
  final String? roomId;
  final String? roomPassword;

  const FfMatch({
    required this.id,
    required this.title,
    required this.modeKey,
    required this.modeLabel,
    required this.startTime,
    this.status = 'active',
    this.map = 'Bermuda',
    this.type = 'Solo',
    this.version = 'TTP',
    this.device = 'Android',
    this.prize = 0,
    this.perKill = 0,
    this.entryFee = 0,
    this.slotsTaken = 0,
    this.slotsTotal = 20,
    this.rules = '',
    this.participants = const [],
    this.isJoined = false,
    this.roomId,
    this.roomPassword,
  });

  /// Decodes the backend `/matches` JSON (snake_case) into an [FfMatch].
  factory FfMatch.fromJson(Map<String, dynamic> j) {
    double d(dynamic v) => (v ?? 0).toDouble();
    int i(dynamic v) => (v ?? 0) as int;
    DateTime parseTime(dynamic v) =>
        DateTime.tryParse('${v ?? ''}')?.toLocal() ?? DateTime.now();
    final parts = (j['participants'] as List?) ?? const [];
    return FfMatch(
      id: i(j['id']),
      title: (j['title'] ?? '').toString(),
      modeKey: (j['mode_key'] ?? '').toString(),
      modeLabel: (j['mode_label'] ?? '').toString(),
      startTime: parseTime(j['start_time']),
      status: (j['status'] ?? 'active').toString(),
      map: (j['map'] ?? 'Bermuda').toString(),
      type: (j['type'] ?? 'Solo').toString(),
      version: (j['version'] ?? 'TTP').toString(),
      device: (j['device'] ?? 'Android').toString(),
      prize: d(j['prize']),
      perKill: d(j['per_kill']),
      entryFee: d(j['entry_fee']),
      slotsTaken: i(j['slots_taken']),
      slotsTotal: j['slots_total'] == null ? 20 : i(j['slots_total']),
      rules: (j['rules'] ?? '').toString(),
      participants: parts
          .whereType<Map>()
          .map((p) => Participant.fromJson(p.cast<String, dynamic>()))
          .toList(),
      isJoined: j['is_joined'] == true,
      roomId: j['room_id']?.toString(),
      roomPassword: j['room_password']?.toString(),
    );
  }

  double get slotProgress => slotsTotal == 0 ? 0 : slotsTaken / slotsTotal;
  bool get isFull => slotsTaken >= slotsTotal;

  /// Short match code shown on Ludo cards, e.g. `#M546263`.
  String get code => '#M$id';

  FfMatch copyWith({bool? isJoined, int? slotsTaken}) => FfMatch(
        id: id,
        title: title,
        modeKey: modeKey,
        modeLabel: modeLabel,
        startTime: startTime,
        status: status,
        map: map,
        type: type,
        version: version,
        device: device,
        prize: prize,
        perKill: perKill,
        entryFee: entryFee,
        slotsTaken: slotsTaken ?? this.slotsTaken,
        slotsTotal: slotsTotal,
        rules: rules,
        participants: participants,
        isJoined: isJoined ?? this.isJoined,
        roomId: roomId,
        roomPassword: roomPassword,
      );
}
