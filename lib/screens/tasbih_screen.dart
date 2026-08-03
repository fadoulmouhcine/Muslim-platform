import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ✅ ضروري
import '../services/settings_provider.dart'; // ✅ ضروري
import '../services/vibration_service.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _counter = 0;
  int _target = 33;

  // NEW: Variable l-Tasbi7
  String _selectedDhikr = "تسبيح مطلق";
  final List<String> _dhikrList = [
    "تسبيح مطلق",
    "سبحان الله",
    "الحمد لله",
    "الله أكبر",
    "أستغفر الله",
    "لا إله إلا الله",
    "لا حول ولا قوة إلا بالله",
    "اللهم صل على محمد",
  ];

  // Settings — driven by SettingsProvider.isHapticEnabled (persisted globally).
  // Local _isVibrationOn is no longer the source of truth; we read from provider.
  bool _isVibrationOn = true; // Will be synced from Provider in build()
  double _vibrationLevel = 1.0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Vibration Logic
    if (_isVibrationOn) {
      _triggerVibration(settings);
    }

    // Ila wsel l-Hadaf (Target)
    if (_counter % _target == 0 && _counter != 0) {
      VibrationService.triggerHaptic(settings, type: HapticType.heavy);
    }
  }

  void _triggerVibration(SettingsProvider settings) {
    switch (_vibrationLevel.toInt()) {
      case 1:
        VibrationService.triggerHaptic(settings, type: HapticType.light);
        break;
      case 2:
        VibrationService.triggerHaptic(settings, type: HapticType.light);
        break;
      case 3:
        VibrationService.triggerHaptic(settings, type: HapticType.medium);
        break;
      case 4:
        VibrationService.triggerHaptic(settings, type: HapticType.heavy);
        break;
      case 5:
        VibrationService.triggerHaptic(settings, type: HapticType.heavy);
        break;
      default:
        VibrationService.triggerHaptic(settings, type: HapticType.light);
    }
  }

  void _resetCounter() {
    setState(() => _counter = 0);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (_isVibrationOn) {
      VibrationService.triggerHaptic(settings, type: HapticType.medium);
    }
  }

  // --- MENU: SELECT DHIKR ---
  void _showDhikrSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400, // N-7ddo l-irtifa3
          child: Column(
            children: [
              const Text(
                "اختر الذكر",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: _dhikrList.length,
                  itemBuilder: (context, index) {
                    final dhikr = _dhikrList[index];
                    final isSelected = dhikr == _selectedDhikr;
                    return ListTile(
                      title: Text(
                        dhikr,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFFC5A059),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedDhikr = dhikr;
                          _counter = 0; // Reset counter melli n-bddlo d-dkr
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MENU: SETTINGS ---
  void _showSettings(SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "إعدادات المسبحة",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "الاهتزاز (Vibration)",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Switch(
                      value: _isVibrationOn,
                      activeTrackColor: const Color(0xFFC5A059),
                      inactiveThumbColor: Colors.grey,
                      onChanged: (val) {
                        setState(() => _isVibrationOn = val);
                        setModalState(() => _isVibrationOn = val);
                        if (val) HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isVibrationOn) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "قوة الاهتزاز",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        // ✅ تحويل رقم قوة الاهتزاز
                        settings
                            .replaceDigits(_vibrationLevel.toInt().toString()),
                        style: const TextStyle(
                          color: Color(0xFFC5A059),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _vibrationLevel,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFFC5A059),
                    inactiveColor: Colors.grey.shade700,
                    onChanged: (val) {
                      setState(() => _vibrationLevel = val);
                      setModalState(() => _vibrationLevel = val);
                      _triggerVibration(settings);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ HAPTIC FIX: Sync _isVibrationOn from the global SettingsProvider
    // every build cycle. This ensures the tasbih counter immediately respects
    // the "Vibration" toggle in General Settings without requiring a restart.
    final settings = Provider.of<SettingsProvider>(context);
    _isVibrationOn = settings.isHapticEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        title: const Text(
          "المسبحة",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(settings),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- TOP CONTROLS (TARGET & DHIKR) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Target Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButton<int>(
                      value: _target,
                      dropdownColor: const Color(0xFF374151),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      underline: Container(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      items: const [33, 100, 1000].map((e) {
                        return DropdownMenuItem(
                          value: e,
                          // ✅ تحويل رقم الهدف داخل القائمة
                          child: Text(
                              "هدف: ${settings.replaceDigits(e.toString())}"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() {
                        _target = val!;
                        _counter = 0;
                      }),
                    ),
                  ),

                  const SizedBox(width: 15),

                  // 2. Dhikr Selector Button
                  GestureDetector(
                    onTap: _showDhikrSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFC5A059).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFFC5A059),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "اختر الذكر",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // --- BIG BUTTON ---
              GestureDetector(
                onTap: _incrementCounter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 280,
                      height: 280, // Zdna chwiya f l-kbouria
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF374151),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: _counter % _target == 0 && _counter != 0
                            ? 1
                            : (_counter % _target) / _target,
                        strokeWidth: 10,
                        color: const Color(0xFFC5A059),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ تحويل رقم العداد الكبير
                        Text(
                          settings.replaceDigits("$_counter"),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Smiyt d-Dhikr (Variable)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _selectedDhikr,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              color: const Color(0xFFC5A059),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Reset Button
              IconButton(
                onPressed: _resetCounter,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white54,
                  size: 30,
                ),
                tooltip: "تصفير",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
