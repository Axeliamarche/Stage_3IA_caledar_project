import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robot_calendar/models/reservation_model.dart';

class RobotPage extends StatefulWidget {
  final DateTime selectedDay;

  const RobotPage({Key? key, required this.selectedDay}) : super(key: key);

  @override
  _RobotPageState createState() => _RobotPageState();
}

class _RobotPageState extends State<RobotPage> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<int> _selectedRobots = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final reservationModel = Provider.of<ReservationModel>(context);
    final reservedRobots = reservationModel.getReservedRobots(widget.selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('Prenotazione Robot'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Inserisci il tuo nome',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _startTime = picked);
                  },
                  child: Text(_startTime != null ? _startTime!.format(context) : 'Inizio'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                  child: Text(_endTime != null ? _endTime!.format(context) : 'Fine'),
                ),
              ],
            ),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                final isReservedByOthers = reservedRobots.contains(index);

                return GestureDetector(
                  onTap: () {
                    if (!isReservedByOthers) {
                      setState(() {
                        if (_selectedRobots.contains(index)) {
                          _selectedRobots.remove(index);
                        } else {
                          _selectedRobots.add(index);
                        }
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      Image.asset('assets/robot1.png'),
                      if (_selectedRobots.contains(index))
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Image.asset('assets/check.png', width: 24, height: 24), // Spunta verde
                        ),
                      if (isReservedByOthers)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Image.asset('assets/cross.png', width: 24, height: 24), // X rossa
                        ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final startTimeString = _startTime?.format(context) ?? 'N/A';
                    final endTimeString = _endTime?.format(context) ?? 'N/A';
                    final name = _nameController.text;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Il nome non può essere vuoto')));
                      return;
                    }

                    try {
                      reservationModel.addReservation(
                        widget.selectedDay,
                        startTimeString,
                        endTimeString,
                        _selectedRobots,
                        name,
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  child: Text('Done'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}