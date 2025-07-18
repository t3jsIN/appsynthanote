// ignore_for_file: empty_catches, unused_local_variable, unused_import

import 'dart:convert';
import 'package:http/http.dart' as http;

enum LinkType { spotify, youtube, appleMusic, soundcloud, bandcamp, generic }

class LinkMetadata {
  final String title;
  final String? artist;
  final String? thumbnail;
  final String? description;
  final LinkType type;
  final String originalUrl;
  final String? platformIcon;

  LinkMetadata({
    required this.title,
    this.artist,
    this.thumbnail,
    this.description,
    required this.type,
    required this.originalUrl,
    this.platformIcon,
  });
}

class LinkService {
  static LinkType detectLinkType(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return LinkType.generic;

    final host = uri.host.toLowerCase();

    if (host.contains('spotify.com') || host.contains('open.spotify.com')) {
      return LinkType.spotify;
    } else if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return LinkType.youtube;
    } else if (host.contains('music.apple.com')) {
      return LinkType.appleMusic;
    } else if (host.contains('soundcloud.com')) {
      return LinkType.soundcloud;
    } else if (host.contains('bandcamp.com')) {
      return LinkType.bandcamp;
    }

    return LinkType.generic;
  }

  static Future<LinkMetadata> fetchMetadata(String url) async {
    final type = detectLinkType(url);

    switch (type) {
      case LinkType.spotify:
        return await _fetchSpotifyMetadata(url);
      case LinkType.youtube:
        return await _fetchYouTubeMetadata(url);
      case LinkType.appleMusic:
        return await _fetchAppleMusicMetadata(url);
      case LinkType.soundcloud:
        return await _fetchSoundCloudMetadata(url);
      case LinkType.bandcamp:
        return await _fetchBandcampMetadata(url);
      case LinkType.generic:
        return await _fetchGenericMetadata(url);
    }
  }

  static Future<LinkMetadata> _fetchSpotifyMetadata(String url) async {
    try {
      // Extract Spotify ID from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 2) {
        final type = pathSegments[0]; // track, album, artist, playlist
        final id = pathSegments[1].split('?')[0]; // Remove query params

        // For demo purposes, we'll create a mock response
        // In production, you'd use Spotify Web API
        return LinkMetadata(
          title: 'Spotify ${type.capitalize()}',
          artist: 'Unknown Artist',
          thumbnail: null,
          description: 'Spotify link',
          type: LinkType.spotify,
          originalUrl: url,
          platformIcon: '🎵',
        );
      }
    } catch (e) {}

    return LinkMetadata(
      title: 'Spotify Link',
      type: LinkType.spotify,
      originalUrl: url,
      platformIcon: '🎵',
    );
  }

  static Future<LinkMetadata> _fetchYouTubeMetadata(String url) async {
    try {
      // Extract video ID
      String? videoId;
      final uri = Uri.parse(url);

      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.first;
      } else if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      }

      if (videoId != null) {
        // For demo purposes, creating mock response
        // In production, you'd use YouTube Data API
        return LinkMetadata(
          title: 'YouTube Video',
          artist: 'Channel Name',
          thumbnail: 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
          description: 'YouTube video',
          type: LinkType.youtube,
          originalUrl: url,
          platformIcon: '📺',
        );
      }
    } catch (e) {}

    return LinkMetadata(
      title: 'YouTube Video',
      type: LinkType.youtube,
      originalUrl: url,
      platformIcon: '📺',
    );
  }

  static Future<LinkMetadata> _fetchAppleMusicMetadata(String url) async {
    return LinkMetadata(
      title: 'Apple Music',
      artist: 'Artist Name',
      type: LinkType.appleMusic,
      originalUrl: url,
      platformIcon: '🍎',
    );
  }

  static Future<LinkMetadata> _fetchSoundCloudMetadata(String url) async {
    return LinkMetadata(
      title: 'SoundCloud Track',
      artist: 'Artist Name',
      type: LinkType.soundcloud,
      originalUrl: url,
      platformIcon: '☁️',
    );
  }

  static Future<LinkMetadata> _fetchBandcampMetadata(String url) async {
    return LinkMetadata(
      title: 'Bandcamp Release',
      artist: 'Artist Name',
      type: LinkType.bandcamp,
      originalUrl: url,
      platformIcon: '🎼',
    );
  }

  static Future<LinkMetadata> _fetchGenericMetadata(String url) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;

      // Try to fetch basic metadata from the webpage
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = response.body;

        // Extract title from HTML
        final titleMatch =
            RegExp(r'<title[^>]*>([^<]+)</title>', caseSensitive: false)
                .firstMatch(content);

        final title = titleMatch?.group(1)?.trim() ?? domain;

        return LinkMetadata(
          title: title,
          description: domain,
          type: LinkType.generic,
          originalUrl: url,
          platformIcon: '🔗',
        );
      }
    } catch (e) {}

    final uri = Uri.parse(url);
    return LinkMetadata(
      title: uri.host,
      type: LinkType.generic,
      originalUrl: url,
      platformIcon: '🔗',
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
