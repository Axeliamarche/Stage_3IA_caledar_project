import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:robot_calendar/models/reservation_model.dart';

// E' una pagina per gestire i robot da prenotare
class RobotPage extends StatefulWidget {
  final DateTime selectedDay;

  const RobotPage({super.key, required this.selectedDay});

  @override
  RobotPageState createState() => RobotPageState();
}
// Aggiorna il stato dell robot da prenotare 
class RobotPageState extends State<RobotPage> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<int> _selectedRobots = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
  }
  // Sincronizza i dati dell'utente che sta facendo una prenotazione
  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedInUser = prefs.getString('loggedInUser') ?? '';
    setState(() {
      _nameController.text = loggedInUser;
    });
  }
  // Crea il layout dei blocchi nella pagina  
  @override
  Widget build(BuildContext context) {
    final reservationModel = Provider.of<ReservationModel>(context);
    final reservedRobots = reservationModel.getReservedRobots(widget.selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation of Robots'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'fill with your name',
              ),
            ),
            const SizedBox(height: 20),
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
                  child: Text(_startTime != null ? _startTime!.format(context) : 'Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _endTime = picked);
                  },
                  child: Text(_endTime != null ? _endTime!.format(context) : 'End'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                final isReservedByOthers = reservedRobots.contains(index);
                return GestureDetector(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RobotCharacteristicsPage(selectedRobot: index),
                      ),
                    );
                  },
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final startTimeString = _startTime?.format(context) ?? 'N/A';
                    final endTimeString = _endTime?.format(context) ?? 'N/A';
                    final name = _nameController.text;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('name cant be empty')));
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
                  child: const Text('Done'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// La pagina delle caratteristiche del robot
class RobotCharacteristicsPage extends StatefulWidget {
  final int selectedRobot;

  const RobotCharacteristicsPage({super.key, required this.selectedRobot});

  @override
  RobotCharacteristicsPageState createState() => RobotCharacteristicsPageState();
}

class RobotCharacteristicsPageState extends State<RobotCharacteristicsPage> {
  late TextEditingController _gpuController;
  late TextEditingController _cpuController;
  late TextEditingController _romController;
  late TextEditingController _ramController;
  bool _rgbLights = false;
  bool _networkCard = false;
  bool _bluetooth = false;

  // Aggiorna dati salvati dall'utente
  @override
  void initState() {
    super.initState();
    _gpuController = TextEditingController();
    _cpuController = TextEditingController();
    _romController = TextEditingController();
    _ramController = TextEditingController();
    _loadRobotCharacteristics();
  }
  // Carica le caratteristiche dei robot  
  Future<void> _loadRobotCharacteristics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gpuController.text = prefs.getString('gpu_${widget.selectedRobot}') ?? '';
      _cpuController.text = prefs.getString('cpu_${widget.selectedRobot}') ?? '';
      _romController.text = prefs.getString('rom_${widget.selectedRobot}') ?? '';
      _ramController.text = prefs.getString('ram_${widget.selectedRobot}') ?? '';
      _rgbLights = prefs.getBool('rgbLights_${widget.selectedRobot}') ?? false;
      _networkCard = prefs.getBool('networkCard_${widget.selectedRobot}') ?? false;
      _bluetooth = prefs.getBool('bluetooth_${widget.selectedRobot}') ?? false;
    });
  }
  // Salva le caratteristiche dei robot
  Future<void> _saveRobotCharacteristics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gpu_${widget.selectedRobot}', _gpuController.text);
    await prefs.setString('cpu_${widget.selectedRobot}', _cpuController.text);
    await prefs.setString('rom_${widget.selectedRobot}', _romController.text);
    await prefs.setString('ram_${widget.selectedRobot}', _ramController.text);
    await prefs.setBool('rgbLights_${widget.selectedRobot}', _rgbLights);
    await prefs.setBool('networkCard_${widget.selectedRobot}', _networkCard);
    await prefs.setBool('bluetooth_${widget.selectedRobot}', _bluetooth);
  }

  // Crea una pagina di specifiche delle robot 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot specs'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _gpuController,
                decoration: const InputDecoration(
                  labelText: 'GPU',
                ),
              ),
              TextField(
                controller: _cpuController,
                decoration: const InputDecoration(
                  labelText: 'CPU',
                ),
              ),
              TextField(
                controller: _romController,
                decoration: const InputDecoration(
                  labelText: 'ROM',
                ),
              ),
              TextField(
                controller: _ramController,
                decoration: const InputDecoration(
                  labelText: 'RAM',
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _rgbLights,
                    onChanged: (value) {
                      setState(() {
                        _rgbLights = value ?? false;
                      });
                    },
                  ),
                  const Text('Luci RGB'),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _networkCard,
                    onChanged: (value) {
                      setState(() {
                        _networkCard = value ?? false;
                      });
                    },
                  ),
                  const Text('Network card'),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _bluetooth,
                    onChanged: (value) {
                      setState(() {
                        _bluetooth = value ?? false;
                      });
                    },
                  ),
                  const Text('Bluetooth'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _saveRobotCharacteristics();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

