import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/vibration_service.dart';
import '../services/app_colors.dart';
import 'settings_screen.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  // STATE
  HijriCalendar _focusedMonth = HijriCalendar.now();
  HijriCalendar? _selectedDay;

  final int _hijriOffset = 0;

  // EVENTS DATABASE
  final Map<String, String> _islamicEvents = {
    "1/1": "رأس السنة الهجرية",
    "10/1": "يوم عاشوراء",
    "12/3": "المولد النبوي الشريف",
    "27/7": "الإسراء والمعراج",
    "15/8": "ليلة النصف من شعبان",
    "1/9": "بداية شهر رمضان المبارك",
    "17/9": "غزوة بدر الكبرى",
    "21/9": "ليلة القدر (تقديرياً)",
    "1/10": "عيد الفطر المبارك",
    "9/12": "يوم عرفة",
    "10/12": "عيد الأضحى المبارك",
  };

  final Color _primaryColor = const Color(0xFFC5A059);
  final Color _accentColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('ar');
    final nowCorrected = DateTime.now().add(Duration(days: _hijriOffset));
    final hNow = HijriCalendar.fromDate(nowCorrected);
    _focusedMonth = hNow;
    _selectedDay = hNow;
  }

  String? _getEventForDay(HijriCalendar day) {
    return _islamicEvents["${day.hDay}/${day.hMonth}"];
  }

  String _getGregorianMonthSpan(
      HijriCalendar focusedMonth, SettingsProvider settings) {
    int daysInMonth =
        focusedMonth.getDaysInMonth(focusedMonth.hYear, focusedMonth.hMonth);
    DateTime startGreg = focusedMonth.hijriToGregorian(
        focusedMonth.hYear, focusedMonth.hMonth, 1);
    DateTime endGreg = focusedMonth.hijriToGregorian(
        focusedMonth.hYear, focusedMonth.hMonth, daysInMonth);

    String startMonthStr = settings.getGregorianMonthName(startGreg.month);
    String endMonthStr = settings.getGregorianMonthName(endGreg.month);

    String spanStr = "";
    if (startGreg.month == endGreg.month && startGreg.year == endGreg.year) {
      spanStr = "$startMonthStr ${startGreg.year}";
    } else if (startGreg.year == endGreg.year) {
      spanStr = "$startMonthStr - $endMonthStr ${startGreg.year}";
    } else {
      spanStr =
          "$startMonthStr ${startGreg.year} - $endMonthStr ${endGreg.year}";
    }

    return settings.replaceDigits(spanStr);
  }

  void _previousMonth() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings);
    setState(() {
      int m = _focusedMonth.hMonth - 1;
      int y = _focusedMonth.hYear;
      if (m < 1) {
        m = 12;
        y--;
      }
      HijriCalendar.setLocal('ar');
      _focusedMonth = HijriCalendar()
        ..hYear = y
        ..hMonth = m
        ..hDay = 1;
    });
  }

  void _nextMonth() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    VibrationService.triggerHaptic(settings);
    setState(() {
      int m = _focusedMonth.hMonth + 1;
      int y = _focusedMonth.hYear;
      if (m > 12) {
        m = 1;
        y++;
      }
      HijriCalendar.setLocal('ar');
      _focusedMonth = HijriCalendar()
        ..hYear = y
        ..hMonth = m
        ..hDay = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    HijriCalendar.setLocal('ar');
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "التقويم الهجري والميلادي",
          style: GoogleFonts.arefRuqaa(
            color: c.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: _primaryColor),
            onPressed: () => _showQuickCalendarSettingsModal(context, settings),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          _buildMonthHeader(settings),
          const SizedBox(height: 8),
          _buildDaysOfWeek(),
          Expanded(
            child: _buildCalendarGrid(settings),
          ),
          _buildEventDetails(settings),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  bool get _isTodaySelected {
    final todayH = HijriCalendar.fromDate(
        DateTime.now().add(Duration(days: _hijriOffset)));
    return _selectedDay != null &&
        _selectedDay!.hYear == todayH.hYear &&
        _selectedDay!.hMonth == todayH.hMonth &&
        _selectedDay!.hDay == todayH.hDay;
  }

  Widget _buildMonthHeader(SettingsProvider settings) {
    final c = AppColors.of(context);
    final String gregSpan = _getGregorianMonthSpan(_focusedMonth, settings);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: c.isDark ? c.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: c.isDark
                ? c.borderColor
                : _primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: c.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Right/Start Chevron (Previous Month)
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
            ),
            color: _primaryColor,
            onPressed: isRtl ? _nextMonth : _previousMonth,
            tooltip: isRtl ? "الشهر التالي" : "Previous Month",
          ),

          // Center Clean Title & Subtitle
          Expanded(
            child: Column(
              children: [
                Text(
                  "${_focusedMonth.toFormat("MMMM")} ${settings.replaceDigits(_focusedMonth.hYear.toString())} هـ",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.arefRuqaa(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$gregSpan م",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Left/End Chevron
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              size: 28,
            ),
            color: _primaryColor,
            onPressed: isRtl ? _previousMonth : _nextMonth,
            tooltip: isRtl ? "الشهر السابق" : "Next Month",
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    final c = AppColors.of(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final days = isArabic
        ? [
            "الإثنين",
            "الثلاثاء",
            "الأربعاء",
            "الخميس",
            "الجمعة",
            "السبت",
            "الأحد"
          ]
        : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                            color: c.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(SettingsProvider settings) {
    final c = AppColors.of(context);
    HijriCalendar.setLocal('ar');

    final int daysInMonth =
        _focusedMonth.getDaysInMonth(_focusedMonth.hYear, _focusedMonth.hMonth);

    final DateTime firstDayGreg = _focusedMonth.hijriToGregorian(
        _focusedMonth.hYear, _focusedMonth.hMonth, 1);
    // Monday = 1 -> startOffset = 0
    final int startOffset = (firstDayGreg.weekday - 1);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: daysInMonth + startOffset,
      itemBuilder: (context, index) {
        if (index < startOffset) return const SizedBox();

        final int dayNum = index - startOffset + 1;

        HijriCalendar.setLocal('ar');
        final currentDayObj = HijriCalendar()
          ..hYear = _focusedMonth.hYear
          ..hMonth = _focusedMonth.hMonth
          ..hDay = dayNum;

        final DateTime gregDate = _focusedMonth.hijriToGregorian(
            _focusedMonth.hYear, _focusedMonth.hMonth, dayNum);

        final nowCorrected = DateTime.now().add(Duration(days: _hijriOffset));
        HijriCalendar.setLocal('ar');
        final todayH = HijriCalendar.fromDate(nowCorrected);

        final bool isToday = (todayH.hYear == currentDayObj.hYear &&
            todayH.hMonth == currentDayObj.hMonth &&
            todayH.hDay == currentDayObj.hDay);

        final bool isSelected = (_selectedDay != null &&
            _selectedDay!.hYear == currentDayObj.hYear &&
            _selectedDay!.hMonth == currentDayObj.hMonth &&
            _selectedDay!.hDay == currentDayObj.hDay);

        final bool hasEvent = _getEventForDay(currentDayObj) != null;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = currentDayObj),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? _primaryColor
                  : (isToday
                      ? _primaryColor.withValues(alpha: 0.15)
                      : c.cardBg),
              border: isToday && !isSelected
                  ? Border.all(color: _primaryColor, width: 1.8)
                  : (isSelected
                      ? Border.all(color: const Color(0xFFE5C17C), width: 1.5)
                      : Border.all(
                          color: c.borderColor.withValues(alpha: 0.6))),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? _primaryColor.withValues(alpha: 0.3)
                      : c.shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Primary Text: Hijri Day Number
                    Text(
                      settings.replaceDigits(dayNum.toString()),
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: (isToday || isSelected)
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isToday ? _primaryColor : c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Secondary Text: Gregorian Day Number
                    Text(
                      settings.replaceDigits(gregDate.day.toString()),
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : c.textMuted,
                      ),
                    ),
                  ],
                ),
                if (hasEvent)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : _accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventDetails(SettingsProvider settings) {
    final c = AppColors.of(context);
    if (_selectedDay == null) return const SizedBox();

    final String? eventName = _getEventForDay(_selectedDay!);
    final String monthName = _selectedDay!.toFormat("MMMM");

    final DateTime gregDate = _selectedDay!.hijriToGregorian(
        _selectedDay!.hYear, _selectedDay!.hMonth, _selectedDay!.hDay);

    final String dayStr = settings.replaceDigits(_selectedDay!.hDay.toString());
    final String yearStr =
        settings.replaceDigits(_selectedDay!.hYear.toString());
    final String hijriFull = "$dayStr $monthName $yearStr هـ";

    final String dayOfWeekName = DateFormat('EEEE', 'ar').format(gregDate);
    final String gregMonthName = settings.getGregorianMonthName(gregDate.month);
    final String gregDayStr = settings.replaceDigits(gregDate.day.toString());
    final String gregYearStr = settings.replaceDigits(gregDate.year.toString());
    final String gregFull = "$gregDayStr $gregMonthName $gregYearStr";

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
                color: c.shadowColor,
                blurRadius: 16,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.calendar_month_rounded,
                      color: _primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Hijri Date
                      Text(
                        hijriFull,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Gregorian Subtitle + Day of week badge
                      Text(
                        "$gregFull م  •  $dayOfWeekName",
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: c.borderColor.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            if (eventName != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _accentColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: _accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        eventName,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    Directionality.of(context) == TextDirection.rtl
                        ? "لا توجد مناسبات إسلامية في هذا اليوم"
                        : "No Islamic events on this day",
                    style: GoogleFonts.cairo(color: c.textMuted, fontSize: 13),
                  ),
                ),
              ),
            if (!_isTodaySelected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: _primaryColor.withValues(alpha: 0.6),
                        width: 1.2),
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: _primaryColor.withValues(alpha: 0.06),
                  ),
                  onPressed: () {
                    final hNow = HijriCalendar.fromDate(
                        DateTime.now().add(Duration(days: _hijriOffset)));
                    setState(() {
                      _focusedMonth = hNow;
                      _selectedDay = hNow;
                    });
                  },
                  icon: const Icon(Icons.today_rounded, size: 18),
                  label: Text(
                    Directionality.of(context) == TextDirection.rtl
                        ? "العودة إلى تاريخ اليوم"
                        : "Back to Today",
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickCalendarSettingsModal(
      BuildContext context, SettingsProvider settings) {
    final c = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<SettingsProvider>(
          builder: (context, s, _) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: c.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFC5A059).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: Color(0xFFC5A059), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "إعدادات عرض التقويم",
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Option 1: Gregorian Month Naming System
                  Text(
                    "نظام أسماء الأشهر الميلادية",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFECEEED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: s.gregorianMonthNaming,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: c.textPrimary),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                          fontSize: 13,
                        ),
                        dropdownColor: c.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(
                            value: 'standard',
                            child: Text("الخليج والدولي (يناير، فبراير...)"),
                          ),
                          DropdownMenuItem(
                            value: 'maghrebi',
                            child: Text("المغرب العربي (ماي، غشت، شتنبر...)"),
                          ),
                          DropdownMenuItem(
                            value: 'levantine',
                            child: Text("المشرق العربي (شباط، آذار، آب...)"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) s.setGregorianMonthNaming(val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Option 2: Number System
                  Text(
                    "نظام الأرقام",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFECEEED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: s.numberType,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: c.textPrimary),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                          fontSize: 13,
                        ),
                        dropdownColor: c.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(
                            value: 'arabic',
                            child: Text("الأرقام العربية (١، ٢، ٣...)"),
                          ),
                          DropdownMenuItem(
                            value: 'latin',
                            child: Text("الأرقام اللاتينية (1, 2, 3...)"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) s.setNumberType(val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  Divider(color: c.borderColor),
                  const SizedBox(height: 14),

                  // Action Button: Navigates to full App Settings Screen
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003527),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SettingsScreen(initialTabIndex: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      label: Text(
                        "الانتقال لجميع إعدادات التطبيق",
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
