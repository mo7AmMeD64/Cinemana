import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:media_kit_video/media_kit_video.dart' as mk;
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../utils/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final List<CinemanaSubtitle> subtitles;
  final int startPosition; // بالثواني

  const PlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.subtitles = const [],
    this.startPosition = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final mk.VideoController _controller;

  // حالة المشغّل
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isBuffering = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  Timer? _hideTimer;

  // ترجمة
  CinemanaSubtitle? _selectedSub;
  double _subFontSize = 16.0;
  Color _subColor = Colors.white;
  Color _subBgColor = Colors.black54;
  bool _subBold = false;
  String _currentSubText = '';

  // إعدادات الترجمة
  bool _showSubSettings = false;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _player = Player();
    _controller = mk.VideoController(_player);

    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _player.stream.buffering.listen((b) {
      if (mounted) setState(() => _isBuffering = b);
    });
    _player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.stream.volume.listen((v) {
      if (mounted) setState(() => _volume = v / 100);
    });

    await _player.open(Media(widget.url));

    if (widget.startPosition > 0) {
      await _player.seek(Duration(seconds: widget.startPosition));
    }

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
    setState(() => _showSubSettings = false);
  }

  void _seekRelative(int seconds) {
    final newPos = _position + Duration(seconds: seconds);
    _player.seek(newPos.isNegative ? Duration.zero : newPos);
    _startHideTimer();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        onDoubleTapDown: (d) {
          final w = MediaQuery.of(context).size.width;
          _seekRelative(d.globalPosition.dx < w / 2 ? -10 : 10);
        },
        child: Stack(fit: StackFit.expand, children: [
          // مشغّل الفيديو
          mk.Video(controller: _controller, fill: Colors.black),

          // مؤشر التحميل
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
            ),

          // الترجمة
          if (_currentSubText.isNotEmpty && _selectedSub != null)
            _buildSubtitleOverlay(),

          // تلميح double-tap
          if (_showControls) _buildDoubleTapHint(),

          // شاشة التحكم
          if (_showControls) _buildControls(),

          // إعدادات الترجمة
          if (_showSubSettings) _buildSubSettings(),
        ]),
      ),
    );
  }

  // ─── الترجمة على الشاشة ───────────────────────────────────────────────────────
  Widget _buildSubtitleOverlay() {
    return Positioned(
      bottom: _showControls ? 90 : 24,
      left: 16, right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _subBgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentSubText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _subFontSize,
              color: _subColor,
              fontWeight: _subBold ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4, offset: const Offset(1, 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── تلميح double tap ─────────────────────────────────────────────────────────
  Widget _buildDoubleTapHint() {
    return Positioned(
      top: 0, bottom: 0, left: 0, right: 0,
      child: Row(children: [
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.replay_10_rounded, color: Colors.white38, size: 32),
                SizedBox(height: 4),
                Text('10 ثواني', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forward_10_rounded, color: Colors.white38, size: 32),
                SizedBox(height: 4),
                Text('10 ثواني', style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─── لوحة التحكم الكاملة ─────────────────────────────────────────────────────
  Widget _buildControls() {
    return Column(children: [
      // شريط علوي
      _buildTopBar(),
      const Spacer(),
      // أزرار التحكم المركزية
      _buildCenterButtons(),
      const Spacer(),
      // شريط التقدم والأدوات
      _buildBottomBar(),
    ]);
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // زر الترجمة
        if (widget.subtitles.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.subtitles_rounded,
              color: _selectedSub != null ? AppTheme.accent : Colors.white,
            ),
            onPressed: () => _showSubtitlePicker(),
          ),
        // زر إعدادات الترجمة
        if (_selectedSub != null)
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, color: Colors.white),
            onPressed: () => setState(() => _showSubSettings = !_showSubSettings),
          ),
        // السرعة
        GestureDetector(
          onTap: _showSpeedPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${_speed}x',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildCenterButtons() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      // ترجيع 10
      IconButton(
        iconSize: 42,
        icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
        onPressed: () => _seekRelative(-10),
      ),
      const SizedBox(width: 24),
      // play/pause
      GestureDetector(
        onTap: () {
          _player.playOrPause();
          _startHideTimer();
        },
        child: Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white, size: 36,
          ),
        ),
      ),
      const SizedBox(width: 24),
      // تقديم 10
      IconButton(
        iconSize: 42,
        icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
        onPressed: () => _seekRelative(10),
      ),
    ]);
  }

  Widget _buildBottomBar() {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(children: [
        // شريط التقدم
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: Colors.white24,
            thumbColor: AppTheme.accent,
            overlayColor: AppTheme.accent.withOpacity(0.3),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) {
              final newPos = Duration(
                milliseconds: (v * _duration.inMilliseconds).toInt(),
              );
              _player.seek(newPos);
              _startHideTimer();
            },
          ),
        ),

        // وقت + صوت
        Row(children: [
          // الوقت
          Text(
            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          // الصوت
          Icon(
            _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white, size: 20,
          ),
          SizedBox(
            width: 80,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: _volume.clamp(0.0, 1.0),
                onChanged: (v) {
                  _player.setVolume(v * 100);
                  _startHideTimer();
                },
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ─── إعدادات الترجمة ─────────────────────────────────────────────────────────
  Widget _buildSubSettings() {
    return Positioned(
      top: 60, right: 8,
      child: GestureDetector(
        onTap: () {}, // منع إغلاق الكونترولز
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xEE1A1A25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إعدادات الترجمة',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              const Divider(color: AppTheme.divider, height: 16),

              // حجم الخط
              _settingRow(
                'حجم الخط',
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                    onPressed: () => setState(() => _subFontSize = (_subFontSize - 2).clamp(10, 32)),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('${_subFontSize.toInt()}',
                    style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    onPressed: () => setState(() => _subFontSize = (_subFontSize + 2).clamp(10, 32)),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                ]),
              ),

              // عريض
              _settingRow(
                'عريض',
                Switch(
                  value: _subBold,
                  onChanged: (v) => setState(() => _subBold = v),
                  activeColor: AppTheme.accent,
                ),
              ),

              // لون الخط
              _settingRow(
                'لون الخط',
                Row(children: [
                  for (final c in [Colors.white, Colors.yellow, Colors.cyan, Colors.greenAccent])
                    GestureDetector(
                      onTap: () => setState(() => _subColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle,
                          border: Border.all(
                            color: _subColor == c ? AppTheme.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ]),
              ),

              // خلفية الترجمة
              _settingRow(
                'الخلفية',
                Row(children: [
                  for (final c in [Colors.black54, Colors.black87, Colors.transparent])
                    GestureDetector(
                      onTap: () => setState(() => _subBgColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: c == Colors.transparent ? null : c,
                          border: Border.all(
                            color: _subBgColor == c ? AppTheme.accent : Colors.white24,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: c == Colors.transparent
                            ? const Icon(Icons.block_rounded, color: Colors.white38, size: 14)
                            : null,
                      ),
                    ),
                ]),
              ),

              // معاينة
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: _subBgColor,
                  child: Text(
                    'معاينة الترجمة',
                    style: TextStyle(
                      color: _subColor,
                      fontSize: _subFontSize,
                      fontWeight: _subBold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingRow(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          control,
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  // ─── اختيار الترجمة ──────────────────────────────────────────────────────────
  void _showSubtitlePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('اختيار الترجمة',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
          ),
          // بدون ترجمة
          ListTile(
            leading: Icon(
              Icons.subtitles_off_rounded,
              color: _selectedSub == null ? AppTheme.accent : AppTheme.textSecondary,
            ),
            title: const Text('بدون ترجمة', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              setState(() { _selectedSub = null; _currentSubText = ''; });
              Navigator.pop(context);
            },
          ),
          ...widget.subtitles.map((sub) => ListTile(
            leading: Icon(
              Icons.subtitles_rounded,
              color: _selectedSub?.lang == sub.lang ? AppTheme.accent : AppTheme.textSecondary,
            ),
            title: Text(sub.label.isNotEmpty ? sub.label : sub.lang,
              style: const TextStyle(color: AppTheme.textPrimary)),
            trailing: _selectedSub?.lang == sub.lang
                ? const Icon(Icons.check_rounded, color: AppTheme.accent) : null,
            onTap: () {
              setState(() => _selectedSub = sub);
              Navigator.pop(context);
              _loadSubtitle(sub);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── تحميل وتحليل الترجمة (SRT/VTT) ─────────────────────────────────────────
  Future<void> _loadSubtitle(CinemanaSubtitle sub) async {
    try {
      final res = await http.get(Uri.parse(sub.url));
      if (res.statusCode == 200) {
        // استخدام utf8.decode لدعم العربية
        final text = utf8.decode(res.bodyBytes, allowMalformed: true);
        final entries = _parseSrt(text);
        // مزامنة مع الموقع الحالي
        _player.stream.position.listen((pos) {
          if (!mounted || _selectedSub?.lang != sub.lang) return;
          final found = entries.firstWhere(
            (e) => pos >= e.start && pos <= e.end,
            orElse: () => _SubEntry(Duration.zero, Duration.zero, ''),
          );
          if (mounted) setState(() => _currentSubText = found.text);
        });
      }
    } catch (_) {}
  }

  List<_SubEntry> _parseSrt(String content) {
    final entries = <_SubEntry>[];
    // دعم SRT و VTT
    final cleaned = content
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'WEBVTT.*?\n\n', dotAll: true), '');

    final blocks = cleaned.trim().split(RegExp(r'\n\n+'));
    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      // ابحث عن سطر التوقيت
      String? timeLine;
      int textStart = 0;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timeLine = lines[i];
          textStart = i + 1;
          break;
        }
      }
      if (timeLine == null) continue;

      final times = timeLine.split('-->');
      if (times.length < 2) continue;

      final start = _parseTime(times[0].trim());
      final end = _parseTime(times[1].trim().split(' ').first);
      final text = lines.sublist(textStart).join('\n').trim();

      if (text.isNotEmpty && start != null && end != null) {
        entries.add(_SubEntry(start, end, text));
      }
    }
    return entries;
  }

  Duration? _parseTime(String t) {
    try {
      // HH:MM:SS,mmm أو HH:MM:SS.mmm
      final clean = t.replaceAll(',', '.');
      final parts = clean.split(':');
      if (parts.length == 3) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final sParts = parts[2].split('.');
        final s = int.parse(sParts[0]);
        final ms = sParts.length > 1
            ? int.parse(sParts[1].padRight(3, '0').substring(0, 3))
            : 0;
        return Duration(hours: h, minutes: m, seconds: s, milliseconds: ms);
      }
    } catch (_) {}
    return null;
  }

  // ─── اختيار السرعة ───────────────────────────────────────────────────────────
  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('سرعة التشغيل',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
          ),
          ..._speeds.map((s) => ListTile(
            title: Text('${s}x', style: const TextStyle(color: AppTheme.textPrimary)),
            trailing: _speed == s
                ? const Icon(Icons.check_rounded, color: AppTheme.accent) : null,
            onTap: () {
              _player.setRate(s);
              setState(() => _speed = s);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SubEntry {
  final Duration start;
  final Duration end;
  final String text;
  _SubEntry(this.start, this.end, this.text);
}
