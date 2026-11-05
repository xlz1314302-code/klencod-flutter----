import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kBackground = Color(0xFF0B0A12);
const Color kPanel = Color(0xFF171523);
const Color kPanel2 = Color(0xFF211D31);
const Color kPurple = Color(0xFF9B70FF);
const Color kGold = Color(0xFFFFD58A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AliGraphicStudio());
}

class AliGraphicStudio extends StatelessWidget {
  const AliGraphicStudio({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kPurple,
      brightness: Brightness.dark,
      surface: kPanel,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'علي جرافيك',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kPanel2,
          hintStyle: const TextStyle(color: Colors.white38),
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: kPurple, width: 1.4),
          ),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const StudioShell(),
    );
  }
}

class StudioShell extends StatefulWidget {
  const StudioShell({super.key});

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  int _selectedIndex = 0;
  bool _loading = true;
  List<Map<String, String>> _projects = [];
  List<String> _savedPalettes = [];

  final List<String> _titles = const [
    'استوديو المصمم',
    'حاسبة الطباعة',
    'مختبر الألوان',
    'مشاريعي',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProjects = prefs.getString('ali_projects_v1');
      final rawPalettes = prefs.getStringList('ali_palettes_v1') ?? [];
      if (rawProjects != null) {
        final decoded = jsonDecode(rawProjects);
        if (decoded is List) {
          _projects = decoded
              .whereType<Map>()
              .map((item) => item.map(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  ))
              .toList();
        }
      }
      _savedPalettes = rawPalettes;
    } catch (_) {
      _projects = [];
      _savedPalettes = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ali_projects_v1', jsonEncode(_projects));
  }

  Future<void> _savePalette(String palette) async {
    if (_savedPalettes.contains(palette)) {
      _showMessage('هذه المجموعة محفوظة بالفعل');
      return;
    }
    setState(() => _savedPalettes.add(palette));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ali_palettes_v1', _savedPalettes);
    _showMessage('تم حفظ مجموعة الألوان');
  }

  Future<void> _removePalette(String palette) async {
    setState(() => _savedPalettes.remove(palette));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ali_palettes_v1', _savedPalettes);
  }

  Future<void> _addProject(String title, String details) async {
    setState(() {
      _projects.insert(0, {
        'title': title,
        'details': details,
        'date': DateTime.now().toString().substring(0, 16),
      });
    });
    await _saveProjects();
  }

  Future<void> _deleteProject(int index) async {
    setState(() => _projects.removeAt(index));
    await _saveProjects();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        projectCount: _projects.length,
        paletteCount: _savedPalettes.length,
        onGo: (index) => setState(() => _selectedIndex = index),
      ),
      const PrintCalculatorPage(),
      ColorLabPage(
        savedPalettes: _savedPalettes,
        onSave: _savePalette,
        onRemove: _removePalette,
      ),
      ProjectsPage(
        projects: _projects,
        onAdd: _addProject,
        onDelete: _deleteProject,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [kPurple, Color(0xFF5A37B8)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 21),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[_selectedIndex],
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Text('ALI GRAPHIC STUDIO',
                    style: TextStyle(fontSize: 9, color: kGold, letterSpacing: 1.2)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'حول التطبيق',
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'علي جرافيك',
              applicationVersion: '1.0.0',
              applicationLegalese: 'صُنع بحب للمصممين — المصمم علي النجار',
              children: const [
                Text('أدوات تصميم وحسابات طباعة ومختبر ألوان تعمل دون الحاجة إلى حساب أو مفتاح API.'),
              ],
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPurple))
          : IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF12101B),
        indicatorColor: kPurple.withOpacity(.22),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.straighten_rounded), label: 'المقاسات'),
          NavigationDestination(icon: Icon(Icons.palette_rounded), label: 'الألوان'),
          NavigationDestination(icon: Icon(Icons.folder_copy_rounded), label: 'مشاريعي'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final int projectCount;
  final int paletteCount;
  final ValueChanged<int> onGo;

  const HomePage({
    super.key,
    required this.projectCount,
    required this.paletteCount,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF35245D), Color(0xFF171323), Color(0xFF171523)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              border: Border.all(color: kPurple.withOpacity(.28)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -7,
                  top: -16,
                  child: Icon(Icons.design_services_rounded,
                      size: 116, color: Colors.white.withOpacity(.055)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.22),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text('مساحة عملك الإبداعية',
                          style: TextStyle(color: kGold, fontSize: 11)),
                    ),
                    const SizedBox(height: 17),
                    const Text('أفكارك تستحق\nتصميماً احترافياً',
                        style: TextStyle(fontSize: 27, height: 1.35, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('كل الأدوات الأساسية للمصمم في مكان واحد.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => onGo(1),
                      icon: const Icon(Icons.calculate_rounded, size: 18),
                      label: const Text('ابدأ حساب المقاسات'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatCard(icon: Icons.folder_special, label: 'مشاريع محفوظة', value: '$projectCount')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(icon: Icons.color_lens, label: 'مجموعات ألوان', value: '$paletteCount')),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'أدوات المصمم', subtitle: 'اختصاراتك اليومية'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.34,
            children: [
              _ToolCard(icon: Icons.aspect_ratio_rounded, title: 'حاسبة الطباعة', subtitle: 'سم إلى بكسل بدقة DPI', color: kPurple, onTap: () => onGo(1)),
              _ToolCard(icon: Icons.colorize_rounded, title: 'مختبر الألوان', subtitle: 'HEX و RGB ولوحات جاهزة', color: const Color(0xFFFF9C78), onTap: () => onGo(2)),
              _ToolCard(icon: Icons.folder_open_rounded, title: 'إدارة المشاريع', subtitle: 'احفظ أفكار وأعمالك', color: const Color(0xFF63C9B0), onTap: () => onGo(3)),
              _ToolCard(icon: Icons.offline_bolt_rounded, title: 'يعمل دون إنترنت', subtitle: 'لا يحتاج حساباً أو API', color: kGold, onTap: () => _showOfflineInfo(context)),
            ],
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: 'مقاسات شائعة', subtitle: 'مرجع سريع قبل بدء التصميم'),
          const SizedBox(height: 10),
          const _QuickSizeRow(name: 'منشور إنستغرام', size: '1080 × 1080 px'),
          const _QuickSizeRow(name: 'ستوري / ريلز', size: '1080 × 1920 px'),
          const _QuickSizeRow(name: 'صورة مصغرة يوتيوب', size: '1280 × 720 px'),
          const _QuickSizeRow(name: 'ورق A4 عند 300 DPI', size: '2480 × 3508 px'),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: kGold, size: 20),
                const SizedBox(height: 6),
                const Text('المصمم علي النجار', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 3),
                Text('إبداع بلا حدود • إصدار 1.0', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(.38))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('مساحة عمل مستقلة'),
        content: Text('الأدوات والحسابات وحفظ المشاريع ومجموعات الألوان تعمل محلياً على جهازك. لا يوجد تسجيل دخول ولا مفتاح API.'),
      ),
    );
  }
}

class PrintCalculatorPage extends StatefulWidget {
  const PrintCalculatorPage({super.key});

  @override
  State<PrintCalculatorPage> createState() => _PrintCalculatorPageState();
}

class _PrintCalculatorPageState extends State<PrintCalculatorPage> {
  final _widthController = TextEditingController(text: '100');
  final _heightController = TextEditingController(text: '200');
  String _unit = 'cm';
  int _dpi = 300;
  int? _pixelWidth;
  int? _pixelHeight;
  double? _area;
  String? _error;

  final List<Map<String, dynamic>> _presets = const [
    {'name': 'A4', 'w': 21.0, 'h': 29.7, 'unit': 'cm'},
    {'name': 'A3', 'w': 29.7, 'h': 42.0, 'unit': 'cm'},
    {'name': 'بطاقة شخصية', 'w': 9.0, 'h': 5.5, 'unit': 'cm'},
    {'name': 'رول أب', 'w': 85.0, 'h': 200.0, 'unit': 'cm'},
    {'name': 'لوحة متر × مترين', 'w': 1.0, 'h': 2.0, 'unit': 'm'},
  ];

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final width = double.tryParse(_widthController.text.trim().replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.'));
    if (width == null || height == null || width <= 0 || height <= 0) {
      setState(() {
        _error = 'أدخل قياساً صحيحاً أكبر من صفر.';
        _pixelWidth = null;
        _pixelHeight = null;
      });
      return;
    }
    final factor = _unit == 'm' ? 1000.0 : (_unit == 'cm' ? 10.0 : 1.0);
    final widthMm = width * factor;
    final heightMm = height * factor;
    setState(() {
      _pixelWidth = ((widthMm / 25.4) * _dpi).round();
      _pixelHeight = ((heightMm / 25.4) * _dpi).round();
      _area = (widthMm * heightMm) / 1000000;
      _error = null;
    });
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _widthController.text = preset['w'].toString();
      _heightController.text = preset['h'].toString();
      _unit = preset['unit'] as String;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      children: [
        const SectionTitle(title: 'حوّل مقاساتك إلى بكسل', subtitle: 'حساب دقيق حسب حجم الطباعة ودقة DPI'),
        const SizedBox(height: 15),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _NumberField(controller: _widthController, label: 'العرض', hint: 'مثال: 100')),
                  const SizedBox(width: 10),
                  Expanded(child: _NumberField(controller: _heightController, label: 'الارتفاع', hint: 'مثال: 200')),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'وحدة القياس'),
                      items: const [
                        DropdownMenuItem(value: 'mm', child: Text('مليمتر (mm)')),
                        DropdownMenuItem(value: 'cm', child: Text('سنتيمتر (cm)')),
                        DropdownMenuItem(value: 'm', child: Text('متر (m)')),
                      ],
                      onChanged: (value) => setState(() => _unit = value ?? 'cm'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _dpi,
                      decoration: const InputDecoration(labelText: 'دقة الطباعة'),
                      items: const [
                        DropdownMenuItem(value: 72, child: Text('72 DPI')),
                        DropdownMenuItem(value: 150, child: Text('150 DPI')),
                        DropdownMenuItem(value: 200, child: Text('200 DPI')),
                        DropdownMenuItem(value: 300, child: Text('300 DPI')),
                        DropdownMenuItem(value: 600, child: Text('600 DPI')),
                      ],
                      onChanged: (value) => setState(() => _dpi = value ?? 300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('احسب المقاس بالبكسل'),
                  style: FilledButton.styleFrom(backgroundColor: kPurple, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ],
          ),
        ),
        if (_pixelWidth != null && _pixelHeight != null) ...[
          const SizedBox(height: 14),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('النتيجة المطلوبة للتصميم', style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _ResultNumber(label: 'العرض', value: _pixelWidth!.toString())),
                    const SizedBox(width: 10),
                    Expanded(child: _ResultNumber(label: 'الارتفاع', value: _pixelHeight!.toString())),
                  ],
                ),
                const SizedBox(height: 10),
                Text('$_pixelWidth × $_pixelHeight px', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 5),
                Text('المساحة: ${_area!.toStringAsFixed(3)} متر مربع  •  $_dpi DPI',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 13),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$_pixelWidth × $_pixelHeight px'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ المقاس')));
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ المقاس'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionTitle(title: 'مقاسات جاهزة', subtitle: 'اضغط على المقاس لتعبئة الحاسبة'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) => ActionChip(
            avatar: const Icon(Icons.crop_free_rounded, size: 16),
            label: Text(preset['name'] as String),
            onPressed: () => _applyPreset(preset),
            backgroundColor: kPanel2,
            side: BorderSide(color: kPurple.withOpacity(.25)),
          )).toList(),
        ),
        const SizedBox(height: 16),
        const _HintBox(text: 'للطباعة عالية الجودة استخدم 300 DPI غالباً. للمطبوعات الكبيرة التي تُشاهد من مسافة يمكن استخدام 150 أو 200 DPI حسب المطبعة.'),
      ],
    );
  }
}

class ColorLabPage extends StatefulWidget {
  final List<String> savedPalettes;
  final Future<void> Function(String) onSave;
  final Future<void> Function(String) onRemove;

  const ColorLabPage({super.key, required this.savedPalettes, required this.onSave, required this.onRemove});

  @override
  State<ColorLabPage> createState() => _ColorLabPageState();
}

class _ColorLabPageState extends State<ColorLabPage> {
  final _hexController = TextEditingController(text: '#9B70FF');
  Color _selectedColor = kPurple;
  String? _colorError;

  static const List<List<String>> _palettes = [
    ['#24143D', '#5B2A86', '#9B70FF', '#D7B9FF', '#FFF1D6'],
    ['#102A43', '#1F6F78', '#46A6A0', '#B7D8C8', '#F4EBDD'],
    ['#301515', '#7D2929', '#D65A45', '#F2A66F', '#F8D9B5'],
    ['#17212B', '#344955', '#5C7A89', '#A8C0CC', '#EAF3F5'],
    ['#202A18', '#526B35', '#9BAF64', '#D5DDA5', '#F4EED8'],
    ['#311B32', '#713C65', '#B46F91', '#E6A6A1', '#F8D9CE'],
    ['#15243A', '#244A73', '#3277A8', '#70B5D1', '#D8F0F3'],
    ['#332B22', '#72543D', '#B58A5A', '#DEC49C', '#F6EBDD'],
  ];

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color? _parseHex(String value) {
    var hex = value.trim().replaceAll('#', '').replaceAll('0x', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _updateColor(String value) {
    final color = _parseHex(value);
    setState(() {
      _selectedColor = color ?? _selectedColor;
      _colorError = color == null ? 'أدخل كود HEX صحيحاً مثل #9B70FF' : null;
    });
  }

  String _hexOf(Color color) => '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

  String _rgbOf(Color color) => 'RGB(${color.red}, ${color.green}, ${color.blue})';

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ $value')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionTitle(title: 'مختبر الألوان', subtitle: 'استخرج قيم اللون واحفظ لوحاتك المفضلة'),
        const SizedBox(height: 14),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('لونك الحالي', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 92,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [BoxShadow(color: _selectedColor.withOpacity(.25), blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: _hexController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'كود HEX',
                  hintText: '#9B70FF',
                  errorText: _colorError,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => _updateColor(_hexController.text),
                  ),
                ),
                onChanged: _updateColor,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _CopyValue(label: 'HEX', value: _hexOf(_selectedColor), onTap: () => _copy(_hexOf(_selectedColor)))),
                  const SizedBox(width: 9),
                  Expanded(child: _CopyValue(label: 'RGB', value: _rgbOf(_selectedColor), onTap: () => _copy(_rgbOf(_selectedColor)))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle(title: 'لوحات ألوان جاهزة', subtitle: 'مجموعات متناسقة لبدايات تصميم مختلفة'),
        const SizedBox(height: 10),
        ..._palettes.asMap().entries.map((entry) {
          final palette = entry.value;
          final key = palette.join(',');
          final saved = widget.savedPalettes.contains(key);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withOpacity(.055))),
            child: Column(
              children: [
                Row(
                  children: palette.map((hex) {
                    final color = _parseHex(hex) ?? Colors.white;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _hexController.text = hex;
                          _updateColor(hex);
                        },
                        child: Container(
                          height: 43,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(child: Text('لوحة ${entry.key + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'نسخ الأكواد',
                      onPressed: () => _copy(palette.join('  ')),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: saved ? 'محفوظة' : 'حفظ اللوحة',
                      onPressed: saved ? null : () => widget.onSave(key),
                      icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                          color: saved ? kGold : Colors.white70, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        if (widget.savedPalettes.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionTitle(title: 'لوحاتي المحفوظة', subtitle: 'تبقى محفوظة على جهازك'),
          const SizedBox(height: 9),
          ...widget.savedPalettes.map((palette) {
            final colors = palette.split(',');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: colors.map((hex) => Expanded(
                        child: Container(height: 31, margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(color: _parseHex(hex) ?? Colors.white, borderRadius: BorderRadius.circular(6))),
                      )).toList(),
                    ),
                  ),
                  IconButton(onPressed: () => _copy(colors.join('  ')), icon: const Icon(Icons.copy, size: 18)),
                  IconButton(onPressed: () => widget.onRemove(palette), icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class ProjectsPage extends StatelessWidget {
  final List<Map<String, String>> projects;
  final Future<void> Function(String, String) onAdd;
  final Future<void> Function(int) onDelete;

  const ProjectsPage({super.key, required this.projects, required this.onAdd, required this.onDelete});

  Future<void> _showAddDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مشروع جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(labelText: 'اسم المشروع', hintText: 'مثال: هوية مطعم')),
              const SizedBox(height: 10),
              TextField(controller: detailsController, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات وتفاصيل', hintText: 'الألوان، المقاسات، أفكار...')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حفظ المشروع')),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty) {
      await onAdd(titleController.text.trim(), detailsController.text.trim());
    }
    titleController.dispose();
    detailsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
          child: Row(
            children: [
              const Expanded(child: SectionTitle(title: 'مساحة مشاريعك', subtitle: 'احفظ أسماء الأعمال وأفكارك وملاحظاتك')),
              FilledButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('جديد'),
                style: FilledButton.styleFrom(backgroundColor: kPurple),
              ),
            ],
          ),
        ),
        Expanded(
          child: projects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 86, height: 86,
                          decoration: BoxDecoration(color: kPanel2, borderRadius: BorderRadius.circular(28)),
                          child: const Icon(Icons.folder_open_rounded, size: 42, color: kPurple),
                        ),
                        const SizedBox(height: 15),
                        const Text('لا توجد مشاريع بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 7),
                        const Text('ابدأ بإضافة مشروعك الأول واحفظ تفاصيله هنا.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.5)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white.withOpacity(.05))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 43, height: 43, decoration: BoxDecoration(color: kPurple.withOpacity(.15), borderRadius: BorderRadius.circular(13)),
                              child: const Icon(Icons.design_services_rounded, color: kPurple)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project['title'] ?? 'مشروع بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                if ((project['details'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(project['details']!, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
                                ],
                                const SizedBox(height: 7),
                                Text(project['date'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'حذف المشروع',
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('حذف المشروع؟'),
                                content: const Text('لن يمكن استرجاع هذا المشروع بعد حذفه.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                                  TextButton(onPressed: () { Navigator.pop(dialogContext); onDelete(index); }, child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('يتم حفظ بياناتك محلياً على هذا الجهاز', style: TextStyle(color: Colors.white.withOpacity(.35), fontSize: 10)),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.055))),
        child: child,
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(17)),
        child: Row(
          children: [
            Icon(icon, color: kGold, size: 23),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ])),
          ],
        ),
      );
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: kPanel,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.15))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 39, height: 39, decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
                const SizedBox(height: 9),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );
}

class _QuickSizeRow extends StatelessWidget {
  final String name;
  final String size;
  const _QuickSizeRow({required this.name, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(color: kPanel, borderRadius: BorderRadius.circular(13)),
        child: Row(
          children: [
            const Icon(Icons.crop_rounded, color: kPurple, size: 18),
            const SizedBox(width: 9),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: Colors.white70))),
            Text(size, style: const TextStyle(fontSize: 11, color: kGold, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _NumberField({required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, hintText: hint),
      );
}

class _ResultNumber extends StatelessWidget {
  final String label;
  final String value;
  const _ResultNumber({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(color: kPanel2, borderRadius: BorderRadius.circular(13)),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kGold)),
          const Text('px', style: TextStyle(fontSize: 10, color: Colors.white54)),
        ]),
      );
}

class _CopyValue extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _CopyValue({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: kPanel2, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ])),
              const Icon(Icons.copy_rounded, size: 16, color: kPurple),
            ],
          ),
        ),
      );
}

class _HintBox extends StatelessWidget {
  final String text;
  const _HintBox({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kPurple.withOpacity(.09), borderRadius: BorderRadius.circular(14), border: Border.all(color: kPurple.withOpacity(.2))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: kGold, size: 19),
            const SizedBox(width: 9),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.6))),
          ],
        ),
      );
}
