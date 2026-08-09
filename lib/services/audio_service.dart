// Web-only prototype audio service.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class AudioService {
  const AudioService();

  void click() => _play('click.wav');
  void flip() => _play('flip.wav');
  void positive() => _play('positive.wav');
  void negative() => _play('negative.wav');
  void special() => _play('special.wav');

  void _play(String fileName) {
    final html.AudioElement audio = html.AudioElement(
      'assets/assets/sounds/$fileName',
    );
    audio.volume = 0.65;
    audio.play();
  }
}
