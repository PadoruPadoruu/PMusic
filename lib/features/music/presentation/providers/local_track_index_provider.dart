import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/local_track.dart';
import 'music_providers.dart';

/// One library traversal shared by recommendation cards and playback lookups.
final localTrackIndexProvider = Provider<LocalTrackIndex>((ref) {
  final tracks = ref.watch(
    libraryTracksProvider.select((library) => library.value),
  );
  return tracks == null
      ? const LocalTrackIndex.empty()
      : LocalTrackIndex(tracks);
});

typedef _IndexedLocalTrack = ({int position, LocalTrack track});

class LocalTrackIndex {
  const LocalTrackIndex.empty()
    : _byId = const {},
      _bySourceId = const {},
      _bySourceUrl = const {};

  factory LocalTrackIndex(Iterable<LocalTrack> tracks) {
    final byId = <String, _IndexedLocalTrack>{};
    final bySourceId = <String, _IndexedLocalTrack>{};
    final bySourceUrl = <String, _IndexedLocalTrack>{};
    var position = 0;
    for (final track in tracks) {
      final indexed = (position: position++, track: track);
      byId.putIfAbsent(track.id, () => indexed);
      final sourceId = track.sourceId?.trim();
      if (sourceId != null && sourceId.isNotEmpty) {
        bySourceId.putIfAbsent(sourceId, () => indexed);
      }
      final sourceUrl = track.sourceUrl?.trim();
      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        bySourceUrl.putIfAbsent(sourceUrl, () => indexed);
      }
    }
    return LocalTrackIndex._(byId, bySourceId, bySourceUrl);
  }

  const LocalTrackIndex._(this._byId, this._bySourceId, this._bySourceUrl);

  final Map<String, _IndexedLocalTrack> _byId;
  final Map<String, _IndexedLocalTrack> _bySourceId;
  final Map<String, _IndexedLocalTrack> _bySourceUrl;

  LocalTrack? firstById(String? id) {
    final normalized = id?.trim();
    return normalized == null || normalized.isEmpty
        ? null
        : _byId[normalized]?.track;
  }

  LocalTrack? firstBySourceUrl(String? url) => _bySourceUrl[url?.trim()]?.track;

  /// Home previously stopped at the first match of either identity. Preserve
  /// library order rather than preferring a later exact local ID match.
  LocalTrack? firstMatching({String? localId, String? sourceId}) {
    final normalizedLocalId = localId?.trim();
    final normalizedSourceId = sourceId?.trim();
    final local = normalizedLocalId == null || normalizedLocalId.isEmpty
        ? null
        : _byId[normalizedLocalId];
    final source = normalizedSourceId == null || normalizedSourceId.isEmpty
        ? null
        : _bySourceId[normalizedSourceId];
    if (local == null) return source?.track;
    if (source == null) return local.track;
    return local.position <= source.position ? local.track : source.track;
  }
}
