// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'models/reservation_model.dart';
import 'robot_page.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReservationModel(),
      child: MaterialApp(
        title: 'Robot Calendar',
        home: ReservationPage(),
      ),
    );
  }
}

class ReservationPage extends StatefulWidget {
  @override
  ReservationPageState createState() => ReservationPageState();
}

class ReservationPageState extends State<ReservationPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _loggedInUser;
  int _selectedIndex = 0;
  late ReservationModel _reservationModel;
  late Timer _timer;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reservationModel = Provider.of<ReservationModel>(context, listen: false);
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _reservationModel.removeExpiredReservations();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Calendar'),
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
        ],
      ),
      body: Center(
        child: _selectedIndex == 0 ? _buildCalendarPage() : _buildWarehousePage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 20,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
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

  Widget _buildCalendarPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Consumer<ReservationModel>(
          builder: (context, reservationModel, child) {
            return TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Week',
                CalendarFormat.week: 'Month',
              },
              selectedDayPredicate: (day) {
                return day.isAfter(DateTime.now().subtract(Duration(days: 1))) && reservationModel.hasReservation(day);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = focusedDay; // Aggiornare il focusedDay quando si seleziona un giorno
                });
                if (selectedDay.isAfter(DateTime.now().subtract(Duration(days: 1)))) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RobotPage(selectedDay: selectedDay),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Non puoi selezionare una data passata.')),
                  );
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay; // Aggiornare il focusedDay quando si cambia pagina
                });
              },
            );
          },
        ),
        SizedBox(height: 20),
        Expanded(
          child: Consumer<ReservationModel>(
            builder: (context, reservationModel, child) {
              final reservations = reservationModel.getReservations();
              return ListView.builder(
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];
                  final isUserEvent = reservation.name == _loggedInUser;
                  return ListTile(
                    minTileHeight: 5,
                    horizontalTitleGap: 5,
                    title: Text('Prenotazione di ${reservation.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                    subtitle: Text('${reservation.startTime} - ${reservation.endTime}, ${reservation.selectedRobots.length} robot'),
                    trailing: isUserEvent
                                ? ElevatedButton(
                                  onPressed: () {
                                    reservationModel.removeReservation(reservation.date);
                                  },
                                  child: Text('Elimina'),
                                  )
                                : null
                  );
                },
              );
            },
          ),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Total Available Robots: $totalAvailableRobots',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Consumer<ReservationModel>(
              builder: (context, reservationModel, child) {
                final reservations = reservationModel.getReservations();
                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return ListTile(
                      title: Text('Prenotazione di ${reservation.name}'),
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
        return AlertDialog(
          title: const Text('Login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                onChanged: (value) {
                  setState(() {
                    _loggedInUser = value;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                onChanged: (value) {
                  // Add password logic here
                },
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
              onPressed: () {
                // Perform login here
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
