import 'package:flutter/material.dart';

class Reservation {
  final DateTime date;
  final String startTime;
  final String endTime;
  final List<int> selectedRobots;
  final String name;

  Reservation({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.selectedRobots,
    required this.name,
  });

  // Funzione per convertire la stringa di orario in oggetto TimeOfDay
  TimeOfDay _timeOfDayFromString(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Funzione per ottenere la data e l'ora di fine della prenotazione come DateTime
  DateTime get endDateTime {
    final endTimeOfDay = _timeOfDayFromString(endTime);
    return DateTime(
      date.year,
      date.month,
      date.day,
      endTimeOfDay.hour,
      endTimeOfDay.minute,
    );
  }
}


class ReservationModel extends ChangeNotifier {
  final List<Reservation> _reservations = [];

  List<Reservation> getReservations() => _reservations;

  List<int> getReservedRobots(DateTime date) {
    return _reservations
        .where((reservation) => reservation.date == date)
        .expand((reservation) => reservation.selectedRobots)
        .toList();
  }

  void addReservation(DateTime date, String startTime, String endTime, List<int> selectedRobots, String name) {
    if (_reservations.any((reservation) => reservation.name == name)) {
      throw Exception('This name is been already used.');
    }
    final newReservation = Reservation(
      date: date,
      startTime: startTime,
      endTime: endTime,
      selectedRobots: selectedRobots,
      name: name,
    );
    _reservations.add(newReservation);
    notifyListeners();
  }

  void removeReservation(DateTime date) {
    _reservations.removeWhere((reservation) => reservation.date == date);
    notifyListeners();
  }

  void removeExpiredReservations() {
    final now = DateTime.now();
    _reservations.removeWhere((reservation) => reservation.endDateTime.isBefore(now));
    notifyListeners();
  }

  bool hasReservation(DateTime day) {
    return _reservations.any((reservation) => reservation.date == day);
  }

  int getTotalAvailableRobotsInMonth(DateTime currentMonth, List<Reservation> reservations) {
    // Calcola la data di inizio e fine del mese corrente
    final DateTime firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final DateTime lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    // Conteggio dei robot disponibili nel mese corrente
    int totalAvailableRobots = 0;
    for (DateTime date = firstDayOfMonth; date.isBefore(lastDayOfMonth.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      totalAvailableRobots += 20; // Numero totale di robot disponibili per giorno
    }

    // Sottrai il numero di robot già prenotati
    for (var reservation in reservations) {
      if (reservation.date.month == currentMonth.month && reservation.date.year == currentMonth.year) {
        totalAvailableRobots -= reservation.selectedRobots.length;
      }
    }

    return totalAvailableRobots;
  }

  int getTotalAvailableRobotsInWeek(DateTime currentWeek, List<Reservation> reservations) {
    // Calcola la data di inizio e fine della settimana corrente
    final DateTime firstDayOfWeek = currentWeek.subtract(Duration(days: currentWeek.weekday - 1));
    final DateTime lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));

    // Conteggio dei robot disponibili nella settimana corrente
    int totalAvailableRobots = 0;
    for (DateTime date = firstDayOfWeek; date.isBefore(lastDayOfWeek.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      totalAvailableRobots += 20; // Numero totale di robot disponibili per giorno
    }

    // Sottrai il numero di robot già prenotati
    for (var reservation in reservations) {
      if (reservation.date.isAfter(firstDayOfWeek.subtract(const Duration(days: 1))) && reservation.date.isBefore(lastDayOfWeek.add(const Duration(days: 1)))) {
        totalAvailableRobots -= reservation.selectedRobots.length;
      }
    }

    return totalAvailableRobots;
  }
}