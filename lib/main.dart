import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Device Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// Dummy Device model
class Device {
  final String id;
  final String name;
  final String imageUrl;
  String ocrValue;
  double cpu;
  double battery;
  double temperature;
  List<PastTelemetry> pastTelemetry;
  Device({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ocrValue,
    required this.cpu,
    required this.battery,
    required this.temperature,
    required this.pastTelemetry,
  });
}

class PastTelemetry {
  final DateTime timestamp;
  final String ocrValue;
  final double cpu;
  final double battery;
  final double temperature;
  PastTelemetry(
      {required this.timestamp,
      required this.ocrValue,
      required this.cpu,
      required this.battery,
      required this.temperature});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Device> _devices = [];
  String _search = '';
  Timer? _timer;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _devices = List.generate(9, (i) {
      return Device(
        id: 'PHN${i + 1}',
        name: 'Phone ${i + 1}',
        imageUrl:
            'https://dummyimage.com/300x600/183153/ffffff&text=Phone+${i + 1}',
        ocrValue: 'VAL${1000 + i}',
        cpu: 10 + _rand.nextInt(60) + _rand.nextDouble(), // 10-70
        battery: 30 + _rand.nextInt(70) + _rand.nextDouble(), // 30-100
        temperature: 27 + _rand.nextInt(15) + _rand.nextDouble(), // 27-42
        pastTelemetry: [],
      );
    }).map((d) {
      // Seed with dummy last 5 entries
      d.pastTelemetry = List.generate(5, (j) {
        return PastTelemetry(
          timestamp: DateTime.now()
              .subtract(Duration(seconds: (5 - j) * 5)),
          ocrValue: 'VAL${1000 + int.parse(d.id.replaceAll(RegExp(r'[^0-9]'), '')) + j}',
          cpu: (d.cpu + _rand.nextDouble() * 10 - 5).clamp(10, 90),
          battery: (d.battery + _rand.nextDouble() * 10 - 5).clamp(10, 100),
          temperature: (d.temperature + _rand.nextDouble() * 4 - 2).clamp(25, 45),
        );
      });
      return d;
    }).toList();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(_simulateUpdate);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _simulateUpdate() {
    for (var d in _devices) {
      d.ocrValue = 'VAL${(1000 + _rand.nextInt(9000))}';
      d.cpu = (d.cpu + _rand.nextDouble() * 14 - 7).clamp(0.0, 100.0);
      d.battery = (d.battery + _rand.nextDouble() * 3 - 1.5).clamp(0.0, 100.0);
      d.temperature =
          (d.temperature + _rand.nextDouble() * 2 - 1).clamp(20.0, 50.0);
      d.pastTelemetry.add(PastTelemetry(
        timestamp: DateTime.now(),
        ocrValue: d.ocrValue,
        cpu: d.cpu,
        battery: d.battery,
        temperature: d.temperature,
      ));
      if (d.pastTelemetry.length > 5) d.pastTelemetry.removeAt(0);
    }
  }

  List<Device> get filteredDevices {
    if (_search.trim().isEmpty) {
      return _devices;
    }
    return _devices.where((d) =>
        d.name.toLowerCase().contains(_search.toLowerCase()) ||
        d.id.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  Color statusColor(double value, String key) {
    // green, orange, red for good, warning, danger
    if (key == 'cpu') {
      if (value < 60) return Colors.green;
      if (value < 85) return Colors.orange;
      return Colors.red;
    }
    if (key == 'battery') {
      if (value > 50) return Colors.green;
      if (value > 20) return Colors.orange;
      return Colors.red;
    }
    if (key == 'temp') {
      if (value < 38) return Colors.green;
      if (value < 43) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }

  void _showDetail(Device device) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${device.name} (${device.id})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 13),
              AspectRatio(
                aspectRatio: 1 / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(device.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
              Text('Latest OCR: ${device.ocrValue}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusBox('CPU', device.cpu, statusColor(device.cpu, 'cpu'), '%'),
                  const SizedBox(width: 10),
                  _statusBox('BAT', device.battery, statusColor(device.battery, 'battery'), '%'),
                  const SizedBox(width: 10),
                  _statusBox('TEMP', device.temperature, statusColor(device.temperature, 'temp'), '°C'),
                ],
              ),
              const SizedBox(height: 19),
              const Text('Past telemetry (latest 5)', style: TextStyle(fontWeight: FontWeight.w500)),
              ...device.pastTelemetry.reversed.map((tele) =>
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.timeline, color: Colors.blue.shade800, size: 22),
                    title: Text('${tele.timestamp.hour}:${tele.timestamp.minute.toString().padLeft(2, '0')}'),
                    subtitle: Text('OCR: ${tele.ocrValue} | CPU: ${tele.cpu.toStringAsFixed(1)}% | BAT: ${tele.battery.toStringAsFixed(1)}% | TEMP: ${tele.temperature.toStringAsFixed(1)}°C'),
                  )
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBox(String label, double value, Color color, String suffix) {
    return Row(
      children: [
        Icon(Icons.fiber_manual_record, color: color, size: 14),
        const SizedBox(width: 2),
        Text(
          '$label: ${value.toStringAsFixed(1)}$suffix',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Telemetry Dashboard'),
        elevation: 0,
        backgroundColor: Colors.blue.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by device name or ID",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                fillColor: Colors.grey.shade50,
                filled: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                itemCount: filteredDevices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.74,
                ),
                itemBuilder: (_, idx) {
                  final device = filteredDevices[idx];
                  return InkWell(
                    onTap: () => _showDetail(device),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blueGrey.withOpacity(0.10),
                              blurRadius: 9,
                              offset: const Offset(2, 2))
                        ],
                        border: Border.all(
                            color: Colors.blue[100]!, width: 1.2),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(device.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${device.name} (${device.id})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text('OCR: ${device.ocrValue}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black87)),
                          const SizedBox(height: 8),
                          _statusBox('CPU', device.cpu, statusColor(device.cpu, 'cpu'), '%'),
                          const SizedBox(height: 3),
                          _statusBox('BAT', device.battery, statusColor(device.battery, 'battery'), '%'),
                          const SizedBox(height: 3),
                          _statusBox('TEMP', device.temperature, statusColor(device.temperature, 'temp'), '°C'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
