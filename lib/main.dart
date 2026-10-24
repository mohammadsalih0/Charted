import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/document_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChartedApp());
}

class ChartedApp extends StatefulWidget {
  const ChartedApp({super.key});

  @override
  State<ChartedApp> createState() => _ChartedAppState();
}

class _ChartedAppState extends State<ChartedApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeMode = (preferences.getBool('darkMode') ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('darkMode', enabled);
    if (mounted) {
      setState(() => _themeMode = enabled ? ThemeMode.dark : ThemeMode.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5766F2),
      brightness: _themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
    );
    return MaterialApp(
      title: 'Charted',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF11131A),
      ),
      home: ScannerHome(
        isDark: _themeMode == ThemeMode.dark,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

class ScannerHome extends StatefulWidget {
  const ScannerHome({
    required this.isDark,
    required this.onThemeChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ScannerHome> createState() => _ScannerHomeState();
}

class _ScannerHomeState extends State<ScannerHome> {
  static final _repositoryUri =
      Uri.parse('https://github.com/mohammadsalih0/charted');
  static const _fileChannel = MethodChannel('com.zentex.charted/files');
  final _picker = ImagePicker();
  final _documentService = DocumentService();
  bool _isProcessing = false;
  String? _error;
  String? _lastExportPath;
  String? _lastExportDisplayPath;
  List<String> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentScans = prefs.getStringList('recent_scans') ?? [];
    });
  }

  Future<void> _saveRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_scans', _recentScans);
  }

  Future<void> _scanFromCamera() async {
    if (kIsWeb) return _showMessage('Camera scanning is available on Android.');
    final image = await _picker.pickImage(
      source: Platform.isAndroid ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 92,
    );
    if (image != null) await _process(File(image.path));
  }

  Future<void> _scanFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    final path = result.isEmpty ? null : result.single.path;
    if (path != null) await _process(File(path));
  }

  Future<void> _process(File image) async {
    setState(() {
      _isProcessing = true;
      _error = null;
      _lastExportPath = null;
      _lastExportDisplayPath = null;
    });
    try {
      final text = await _documentService.recognizeText(image);
      final output = await _documentService.createPdf(text);
      final fileName = output.split('/').last.split('\\').last;
      final displayPath = 'Downloads/Charted/$fileName';
      if (!mounted) return;
      setState(() {
        _lastExportPath = output;
        _lastExportDisplayPath = displayPath;
        if (!_recentScans.contains(output)) {
          _recentScans.insert(0, output);
          if (_recentScans.length > 20) {
            _recentScans = _recentScans.sublist(0, 20);
          }
        }
      });
      await _saveRecentScans();
      _showMessage('PDF saved to $displayPath');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openScan(String path) async {
    try {
      await _fileChannel.invokeMethod('openFile', {'path': path});
    } catch (e) {
      if (mounted) _showMessage('Unable to preview PDF: $e');
    }
  }

  Future<void> _shareScan(String path) async {
    try {
      await _fileChannel.invokeMethod('shareFile', {'path': path});
    } catch (e) {
      if (mounted) _showMessage('Unable to share PDF: $e');
    }
  }

  Future<void> _deleteScan(String path) async {
    setState(() {
      _recentScans.remove(path);
    });
    await _saveRecentScans();
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _openRepository() async {
    final opened = await launchUrl(
      _repositoryUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showMessage('Unable to open the repository URL.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: const Text(
          'charted',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
          Switch(
            value: widget.isDark,
            onChanged: widget.onThemeChanged,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
            children: [
              Text(
                'Turn paper into\nsomething searchable.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                'Scan a document, extract its text locally, and save a clean PDF. '
                'Your files never leave this device.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),
              _ScanCard(
                isProcessing: _isProcessing,
                onCamera: _scanFromCamera,
                onFile: _scanFromFile,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _StatusBanner(
                  icon: Icons.error_outline,
                  text: _error!,
                  color: colors.error,
                ),
              ],
              if (_lastExportPath != null && _lastExportDisplayPath != null) ...[
                const SizedBox(height: 14),
                _StatusBanner(
                  icon: Icons.check_circle_outline,
                  text: 'Done. Your PDF is ready at $_lastExportDisplayPath',
                  color: Colors.green.shade700,
                ),
              ],
              const SizedBox(height: 42),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Scans',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_recentScans.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        setState(() => _recentScans.clear());
                        await _saveRecentScans();
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentScans.isEmpty)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No recent scans yet. Scan a document above to get started.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                ..._recentScans.map((path) {
                  final fileName = path.split('/').last.split('\\').last;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.picture_as_pdf, color: colors.primary),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Preview',
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () => _openScan(path),
                            ),
                            IconButton(
                              tooltip: 'Share',
                              icon: const Icon(Icons.share_outlined),
                              onPressed: () => _shareScan(path),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteScan(path),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 42),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.code_outlined, color: colors.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Open source repository',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _openRepository,
                              child: const Text(
                                'https://github.com/mohammadsalih0/charted',
                                style: TextStyle(
                                  color: Color(0xFF5766F2),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.isProcessing,
    required this.onCamera,
    required this.onFile,
  });

  final bool isProcessing;
  final VoidCallback onCamera;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome, color: colors.primary, size: 26),
            const SizedBox(height: 22),
            Text(
              isProcessing ? 'Reading your document…' : 'Ready when you are',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isProcessing
                  ? 'Charted is using on-device OCR and preparing your PDF.'
                  : 'Place one page in view with good lighting for the best result.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            if (isProcessing)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Open camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onFile,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Choose a file'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
