import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/reservation_model.dart';
import 'robot_page.dart';
import 'dart:async';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserModel()),
        ChangeNotifierProvider(create: (context) => ReservationModel()),
        ChangeNotifierProvider(create: (context) => ThemeModel()),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          return MaterialApp(
            title: 'CalendaRobot',
            themeMode: themeModel.themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const ReservationPage(),
          );
        },
      ),
    );
  }
}

class RobotCharacteristics {
  String gpu;
  String cpu;
  String rom;
  String ram;
  bool bluetooth;
  bool networkCard;
  bool rgbLights;

  RobotCharacteristics({
    required this.gpu,
    required this.cpu,
    required this.rom,
    required this.ram,
    this.bluetooth = false,
    this.networkCard = false,
    this.rgbLights = false,
  });
}

class UserModel with ChangeNotifier {
  String? _loggedInUser;

  String? get loggedInUser => _loggedInUser;

  void login(String username) {
    _loggedInUser = username;
    notifyListeners();
  }

  void logout() {
    _loggedInUser = null;
    notifyListeners();
  }
}

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _selectedIndex = 0;
  late ReservationModel _reservationModel;
  late UserModel _userModel;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _reservationModel = Provider.of<ReservationModel>(context, listen: false);
    _userModel = Provider.of<UserModel>(context, listen: false);
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      _reservationModel.removeExpiredReservations();
    });
  }
  
  @override
  void dispose() {
    // Cancella il timer quando il widget viene distrutto
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CalendaRobot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showLoginDialog(context);
            },
          ),
          
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.month ? Icons.view_week : Icons.view_module),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month ? CalendarFormat.week : CalendarFormat.month;
              });
            },
          ),
          Consumer<ThemeModel>(
            builder: (context, themeModel, child) {
              return IconButton(
                icon: Icon(themeModel.isDarkMode ? Icons.brightness_7 : Icons.brightness_2),
                onPressed: () {
                  themeModel.toggleTheme();
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _selectedIndex == 0 ? _buildCalendarPage(context) : _buildWarehousePage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Warehouse',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TableCalendar(
          focusedDay: DateTime.now(),
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Week',
            CalendarFormat.week: 'Month',
          },
          selectedDayPredicate: (day) {
            return _reservationModel.hasReservation(day);
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RobotPage(selectedDay: selectedDay),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You cant select a previous date.')),
                  );
                }
              },
        ),
        const SizedBox(height: 20),
        Consumer2<ReservationModel, UserModel>(
          builder: (context, reservationModel, userModel, child) {
            final reservations = reservationModel.getReservations();
            return Column(
              children: reservations.map((reservation) {
                final isUserEvent = reservation.name == userModel.loggedInUser;
                return Column(
                  children: [
                    Text(
                      'Reservation of ${reservation.name}: ${reservation.startTime} - ${reservation.endTime}, ${reservation.selectedRobots.length} robot',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (isUserEvent)
                      ElevatedButton(
                        onPressed: () {
                          if (reservation.name == userModel.loggedInUser) {
                            reservationModel.removeReservation(reservation.date);
                          }
                        },
                        child: const Text('Delete'),
                      ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWarehousePage() {
    final currentDate = _calendarFormat == CalendarFormat.week ? DateTime.now() : DateTime.now().subtract(Duration(days: DateTime.now().day - 1));
    final totalAvailableRobots = _calendarFormat == CalendarFormat.month
        ? _reservationModel.getTotalAvailableRobotsInMonth(currentDate, _reservationModel.getReservations())
        : _reservationModel.getTotalAvailableRobotsInWeek(currentDate, _reservationModel.getReservations());

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Warehouse for ${_calendarFormat == CalendarFormat.month ? 'Month' : 'Week'}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'Total Available Robots: $totalAvailableRobots',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<ReservationModel>(
              builder: (context, reservationModel, child) {
                final reservations = reservationModel.getReservations();
                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return ListTile(
                      title: Text('Reservation of ${reservation.name}'),
                      subtitle: Text('${reservation.startTime} - ${reservation.endTime}, ${reservation.selectedRobots.length} robot'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final usernameController = TextEditingController();
        final passwordController = TextEditingController();

        return AlertDialog(
          title: const Text('Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final username = usernameController.text;
                final password = passwordController.text;

                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username and password cant be empty!')));
                  return;
                }

                final savedPassword = prefs.getString(username);

                if (savedPassword == null) {
                  // Salva il nuovo account
                  await prefs.setString(username, password);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created with success!')));
                } else if (savedPassword == password) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login created with success!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('wrong Password!')));
                  return;
                }

                Provider.of<UserModel>(context, listen: false).login(username);

                Navigator.of(context).pop();
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }
}

class ThemeModel with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}