import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/dream.dart';
import '../widgets/dream_card.dart';
import '../services/auth_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final _fs = FirestoreService();
  final _auth = AuthService();

  
  List<Dream> _dreamsForDay = [];
  
  Map<DateTime, List<Dream>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Rüyaları tarihe göre grupla (EventLoader için)
  Map<DateTime, List<Dream>> _groupDreamsByDate(List<Dream> dreams) {
    Map<DateTime, List<Dream>> data = {};
    for (var dream in dreams) {
      final date = DateTime(dream.createdAt.year, dream.createdAt.month, dream.createdAt.day);
      if (data[date] == null) data[date] = [];
      data[date]!.add(dream);
    }
    return data;
  }

  List<Dream> _getDreamsForDay(DateTime day) {
    // Saat farkını yoksayarak gün kontrolü
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Giriş yapmalısınız'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rüya Takvimi'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Dream>>(
        stream: _fs.streamDreamsForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }

          final allDreams = snapshot.data ?? [];
          _events = _groupDreamsByDate(allDreams);
          
          // Seçili günün rüyalarını güncelle
          if (_selectedDay != null) {
            _dreamsForDay = _getDreamsForDay(_selectedDay!);
          } else {
             _dreamsForDay = _getDreamsForDay(DateTime.now());
          }

          return Column(
            children: [
              
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1A47).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TableCalendar<Dream>(
                  locale: 'tr_TR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getDreamsForDay,
                  
                  // -- Stil --
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekendStyle: TextStyle(color: Color(0xFFFECA57)),
                    weekdayStyle: TextStyle(color: Colors.white70),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Color(0xFFFECA57)),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFFFECA57),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF5B6CFF).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF5B6CFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _selectedDay == null 
                        ? 'Seçili Gün' 
                        : DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDay!),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_dreamsForDay.length} Rüya', style: const TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Liste ---
              Expanded(
                child: _dreamsForDay.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.nightlight_round, size: 48, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(
                              'Bu tarihte rüya kaydı yok.',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _dreamsForDay.length,
                        itemBuilder: (context, index) {
                          return DreamCard(dream: _dreamsForDay[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
