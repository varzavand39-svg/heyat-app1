shohadaamameh, [9/2/2026 03:13 PM]
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// آدرس اختصاصی دیتابیس هیئت شما
const String dataUrl = 'https://raw.githubusercontent.com/Varzavand-svg/heyat-app1/main/data.json';

void main() {
  runApp(const HeyatApp());
}

class HeyatApp extends StatelessWidget {
  const HeyatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هیئت مجاهدین حسینی شهدای امامه',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4332),
          primary: const Color(0xFF1B4332),
          secondary: const Color(0xFFC9A227),
          surface: Colors.white,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  final String _currentAppVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('heyat_full_cache');
    if (cached != null) {
      setState(() {
        _data = jsonDecode(cached);
        _isLoading = false;
      });
    }

    try {
      final res = await http.get(Uri.parse(dataUrl)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        await prefs.setString('heyat_full_cache', jsonEncode(decoded));
        setState(() {
          _data = decoded;
          _isLoading = false;
        });
        _checkAppUpdate(decoded['app_info']);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _checkAppUpdate(Map<String, dynamic>? appInfo) {
    if (appInfo == null) return;
    final latest = appInfo['latest_version'] ?? _currentAppVersion;
    if (latest != _currentAppVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.system_update, color: Color(0xFF1B4332)),
                SizedBox(width: 8),
                Text('نسخه جدید اپلیکیشن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              appInfo['update_message'] ?? 'نسخه جدید با امکانات ارتقایافته آماده دانلود است.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بعداً'),
              ),
              ElevatedButton(

shohadaamameh, [9/2/2026 03:13 PM]
style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'متن التماس دعا یا نام مورد نظر...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('نیت شما با موفقیت ثبت شد.')),
              );
            },
            child: const Text('ثبت نیت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = data?['prayer_times'] ?? {};
    final featured = data?['featured_martyr'] ?? {};
    final event = (data?['events'] as List? ?? []).isNotEmpty ? data!['events'][0] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1B4332).withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mosque, size: 20, color: Color(0xFF1B4332)),
                  const SizedBox(width: 6),
                  Text(pt['location'] ?? 'اوقات شرعی امامه', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  _prayerBadge('صبح', pt['fajr'] ?? '--:--'),
                  const SizedBox(width: 8),
                  _prayerBadge('ظهر', pt['dhuhr'] ?? '--:--'),
                  const SizedBox(width: 8),
                  _prayerBadge('مغرب', pt['maghrib'] ?? '--:--'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (featured.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const linearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC9A227), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFC9A227), borderRadius: BorderRadius.circular(8)),
                      child: const Text('شهید شاخص هفته', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(featured['date'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),

shohadaamameh, [9/2/2026 03:13 PM]
],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      backgroundImage: NetworkImage(featured['photo_url'] ?? ''),
                      onBackgroundImageError: (_, __) {},
                      child: (featured['photo_url'] == null || featured['photo_url'].isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(featured['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(featured['operation'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('«${featured['will'] ?? ''}»', style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        const SizedBox(height: 14),
        if (event != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: Color(0xFFC9A227)),
                      const SizedBox(width: 8),
                      Text(event['title'] ?? 'مراسم پیش‌رو', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 16),
                  Text('🎤 سخنران: ${event['speaker']}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('🏴 مداح: ${event['eulogist']}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('⏰ زمان: ${event['date_time']}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        const Text('امکانات و خدمات هیئت', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _quickTile(Icons.favorite_border, 'التماس دعا', () => _showPrayerRequestDialog(context)),
            _quickTile(Icons.touch_app, 'صلوات‌شمار', () => onNavigate(3)),
            _quickTile(Icons.auto_stories, 'ادعیه هیئت', () => onNavigate(2)),
            _quickTile(Icons.military_tech, 'یادمان شهدا', () => onNavigate(1)),
            _quickTile(Icons.volunteer_activism, 'نذورات', () => onNavigate(4)),
            _quickTile(Icons.live_tv, 'پخش آنلاین', () => openUrl(data?['media']?['live_stream_url'] ?? 'https://aparat.com')),
          ],
        ),
      ],
    );
  }

  Widget _prayerBadge(String name, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF0F4F2), borderRadius: BorderRadius.circular(6)),
      child: Text('$name: $time', style: const TextStyle(fontSize: 10, color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
    );
  }

shohadaamameh, [9/2/2026 03:13 PM]
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white),
                onPressed: () {
                  _openUrl(appInfo['download_url'] ?? '');
                  Navigator.pop(ctx);
                },
                child: const Text('دانلود نسخه جدید'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان باز کردن لینک وجود ندارد')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B4332)),
        ),
      );
    }

    final pages = [
      HomeDashboard(
        data: _data,
        onNavigate: (idx) => setState(() => _currentIndex = idx),
        openUrl: _openUrl,
      ),
      MartyrsScreen(martyrs: _data?['martyrs'] ?? []),
      PrayersScreen(prayers: _data?['prayers'] ?? []),
      SalawatCounterScreen(pledgeData: _data?['salawat_pledge'] ?? {}),
      MoreMenuScreen(data: _data, openUrl: _openUrl),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _data?['header']?['title'] ?? 'هیئت مجاهدین حسینی',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              _data?['header']?['subtitle'] ?? 'شهدای امامه',
              style: const TextStyle(fontSize: 12, color: Color(0xFFD4AF37)),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B4332),
        elevation: 1,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.military_tech_outlined), selectedIcon: Icon(Icons.military_tech), label: 'شهدا'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'ادعیه'),
          NavigationDestination(icon: Icon(Icons.touch_app_outlined), selectedIcon: Icon(Icons.touch_app), label: 'ذکرشمار'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'خدمات'),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(int) onNavigate;
  final Function(String) openUrl;

  const HomeDashboard({super.key, required this.data, required this.onNavigate, required this.openUrl});

  void _showPrayerRequestDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFC9A227)),
            SizedBox(width: 8),
            Text('صندوق التماس دعا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نام بیمار، درگذشتگان یا نیت معنوی خود را بنویسید تا در پایان جلسه هفتگی قرائت و دعا شود:',

shohadaamameh, [9/2/2026 03:13 PM]
Widget _quickTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(backgroundColor: const Color(0xFF1B4332).withOpacity(0.08), child: Icon(icon, color: const Color(0xFF1B4332), size: 20)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class PrayersScreen extends StatelessWidget {
  final List prayers;
  const PrayersScreen({super.key, required this.prayers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prayers.length,
      itemBuilder: (ctx, i) {
        final p = prayers[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            leading: const Icon(Icons.menu_book, color: Color(0xFF1B4332)),
            title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF1B4332).withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        p['arabic'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, height: 1.8, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p['farsi'] ?? '',
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SalawatCounterScreen extends StatefulWidget {
  final Map pledgeData;
  const SalawatCounterScreen({super.key, required this.pledgeData});

  @override
  State<SalawatCounterScreen> createState() => _SalawatCounterScreenState();
}

class _SalawatCounterScreenState extends State<SalawatCounterScreen> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadSalawat();
  }

  Future<void> _loadSalawat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _count = prefs.getInt('user_salawat_count') ?? 0);
  }

  Future<void> _increment() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    setState(() => _count++);
    await prefs.setInt('user_salawat_count', _count);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _count = 0);
    await prefs.setInt('user_salawat_count', 0);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.pledgeData['target'] ?? 14000;
    final base = widget.pledgeData['base_count'] ?? 0;
    final total = base + _count;
    final progress = (total / target).clamp(0.0, 1.0);

shohadaamameh, [9/2/2026 03:13 PM]
margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1B4332).withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF1B4332)),
                  ),
                  title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('شهادت: ${m['martyrdom_date']} | ${m['operation']}', style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(String) openUrl;

  const MoreMenuScreen({super.key, required this.data, required this.openUrl});

  @override
  Widget build(BuildContext context) {
    final don = data?['donations'] ?? {};
    final con = data?['contacts'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.volunteer_activism, color: Color(0xFF1B4332)),
          title: const Text('نذورات و شفافیت مالی', style: TextStyle(fontWeight: FontWeight.bold)),
          children: [
            ListTile(
              title: Text(don['card_number'] ?? ''),
              subtitle: Text('به‌نام: ${don['account_owner']}'),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: don['card_number'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شماره کارت کپی شد')));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(don['financial_report']?['last_expense'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            )
          ],
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.location_on, color: Color(0xFF1B4332)),
          title: const Text('آدرس حسینیه'),
          subtitle: Text(con['address'] ?? ''),
          trailing: IconButton(icon: const Icon(Icons.navigation), onPressed: () => openUrl(con['map_url'] ?? '')),
        ),
        ListTile(
          leading: const Icon(Icons.phone, color: Color(0xFF1B4332)),
          title: const Text('تماس با خادمین'),
          subtitle: Text(con['phone'] ?? ''),
          onTap: () => openUrl('tel:${con['phone']}'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: () => openUrl(con['telegram'] ?? '')),
            IconButton(icon: const Icon(Icons.chat, color: Colors.orange), onPressed: () => openUrl(con['eitaa'] ?? '')),
            IconButton(icon: const Icon(Icons.chat_bubble, color: Colors.green), onPressed: () => openUrl(con['bale'] ?? '')),
          ],
        )
      ],
    );
  }
}

shohadaamameh, [9/2/2026 03:13 PM]
return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1B4332),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  widget.pledgeData['title'] ?? 'نذر جمعی صلوات شهدای امامه',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress, minHeight: 8, color: const Color(0xFFC9A227), backgroundColor: Colors.white24),
                const SizedBox(height: 8),
                Text('$total صلوات از نذر $target', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: InkWell(
            onTap: _increment,
            borderRadius: BorderRadius.circular(120),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
                boxShadow: [BoxShadow(color: const Color(0xFF1B4332).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('اللهم صل علی محمد و آل محمد', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC9A227), fontSize: 11)),
                  const SizedBox(height: 8),
                  Text('$_count', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('لمس کنید', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, color: Colors.grey),
            label: const Text('صفر کردن شمارش شخصی', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        )
      ],
    );
  }
}

class MartyrsScreen extends StatefulWidget {
  final List martyrs;
  const MartyrsScreen({super.key, required this.martyrs});

  @override
  State<MartyrsScreen> createState() => _MartyrsScreenState();
}

class _MartyrsScreenState extends State<MartyrsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.martyrs.where((m) => (m['name'] ?? '').toString().contains(_q)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'جستجوی نام شهید...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1B4332)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final m = list[i];
              return Card(
