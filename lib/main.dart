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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  List<Device> _devices = [];
  String _search = '';
  Timer? _timer;
  final Random _rand = Random();
  int? _sortColumnIndex;
  bool _sortAsc = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _devices = List.generate(9, (i) {
      return Device(
        id: 'PHN${i + 1}',
        name: 'Phone ${i + 1}',
        imageUrl:
            'https://dummyimage.com/128x200/183153/ffffff&text=Phone+${i + 1}',
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
    _tabController.dispose();
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
    // Resort after update
    if (_sortColumnIndex != null) {
      _sortDevices(_sortColumnIndex!, _sortAsc);
    }
  }

  List<Device> get filteredDevices {
    List<Device> base = _devices;
    if (_search.trim().isNotEmpty) {
      base = base
          .where((d) =>
              d.name.toLowerCase().contains(_search.toLowerCase()) ||
              d.id.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return base;
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
          child: SingleChildScrollView(
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
                SizedBox(
                  height: 180,
                  child: ListView(
                    children: device.pastTelemetry.reversed
                        .map((tele) => ListTile(
                              dense: true,
                              leading: Icon(Icons.timeline, color: Colors.blue.shade800, size: 22),
                              title: Text('${tele.timestamp.hour}:${tele.timestamp.minute.toString().padLeft(2, '0')}'),
                              subtitle: Text(
                                  'OCR: ${tele.ocrValue} | CPU: ${tele.cpu.toStringAsFixed(1)}% | BAT: ${tele.battery.toStringAsFixed(1)}% | TEMP: ${tele.temperature.toStringAsFixed(1)}°C'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBox(String label, double value, Color color, String suffix) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  void _sortDevices(int columnIndex, bool asc) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAsc = asc;
      Comparator<Device>? cmp;
      switch (columnIndex) {
        case 1: // OCR Value
          cmp = (a, b) => a.ocrValue.compareTo(b.ocrValue);
          break;
        case 2: // CPU
          cmp = (a, b) => a.cpu.compareTo(b.cpu);
          break;
        case 3: // Battery
          cmp = (a, b) => a.battery.compareTo(b.battery);
          break;
        case 4: // Temperature
          cmp = (a, b) => a.temperature.compareTo(b.temperature);
          break;
        default:
          return;
      }
      if (cmp != null) {
        _devices.sort((a, b) => asc ? cmp!(a, b) : cmp!(b, a));
      }
    });
  }

  Widget _buildDetailsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: TextField(
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
          ),
          const SizedBox(height: 7),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 950,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 18,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAsc,
                    columns: [
                      const DataColumn(label: Text('Image')),
                      DataColumn(
                        label: Row(
                          children: const [
                            Text('OCR Value'),
                            Icon(Icons.sort, size: 14, color: Colors.grey),
                          ],
                        ),
                        onSort: (i, asc) => _sortDevices(i, asc),
                      ),
                      DataColumn(
                        label: Row(
                          children: const [
                            Text('CPU (%)'),
                            Icon(Icons.sort, size: 14, color: Colors.grey),
                          ],
                        ),
                        numeric: true,
                        onSort: (i, asc) => _sortDevices(i, asc),
                      ),
                      DataColumn(
                        label: Row(
                          children: const [
                            Text('Battery (%)'),
                            Icon(Icons.sort, size: 14, color: Colors.grey),
                          ],
                        ),
                        numeric: true,
                        onSort: (i, asc) => _sortDevices(i, asc),
                      ),
                      DataColumn(
                        label: Row(
                          children: const [
                            Text('Temp (°C)'),
                            Icon(Icons.sort, size: 14, color: Colors.grey),
                          ],
                        ),
                        numeric: true,
                        onSort: (i, asc) => _sortDevices(i, asc),
                      ),
                      const DataColumn(label: Text('Identifier')),
                    ],
                    rows: filteredDevices.map((device) {
                      return DataRow(
                        cells: [
                          DataCell(
                            GestureDetector(
                              onTap: () => _showDetail(device),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(device.imageUrl, width: 46, height: 70, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          DataCell(Text(device.ocrValue)),
                          DataCell(
                            Container(
                              decoration: BoxDecoration(
                                color: statusColor(device.cpu, 'cpu').withOpacity(0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.memory,
                                    size: 15,
                                    color: statusColor(device.cpu, 'cpu'),
                                  ),
                                  const SizedBox(width: 3),
                                  Text('${device.cpu.toStringAsFixed(1)}%'),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              decoration: BoxDecoration(
                                color: statusColor(device.battery, 'battery').withOpacity(0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    device.battery > 75
                                        ? Icons.battery_full
                                        : device.battery > 45
                                            ? Icons.battery_5_bar
                                            : device.battery > 15
                                                ? Icons.battery_2_bar
                                                : Icons.battery_alert,
                                    size: 15,
                                    color: statusColor(device.battery, 'battery'),
                                  ),
                                  const SizedBox(width: 3),
                                  Text('${device.battery.toStringAsFixed(1)}%'),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              decoration: BoxDecoration(
                                color: statusColor(device.temperature, 'temp').withOpacity(0.13),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.thermostat,
                                    size: 15,
                                    color: statusColor(device.temperature, 'temp'),
                                  ),
                                  const SizedBox(width: 3),
                                  Text('${device.temperature.toStringAsFixed(1)}°C'),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: () => _showDetail(device),
                              child: Text(
                                device.id,
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onSelectChanged: (_) => _showDetail(device),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    // Dummy analytics charts, using simple placeholders/bars
    double avgCPU = _devices.map((d) => d.cpu).fold(0.0, (s, v) => s + v) / _devices.length;
    double avgBattery = _devices.map((d) => d.battery).fold(0.0, (s, v) => s + v) / _devices.length;
    double avgTemp = _devices.map((d) => d.temperature).fold(0.0, (s, v) => s + v) / _devices.length;
    int cpuHigh = _devices.where((d) => d.cpu > 85).length;
    int batLow = _devices.where((d) => d.battery < 20).length;
    int tempHigh = _devices.where((d) => d.temperature > 43).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telemetry Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          Row(
            children: [
              _summaryBox('Avg. CPU', avgCPU, Icons.memory, statusColor(avgCPU, 'cpu'), "${avgCPU.toStringAsFixed(1)}%"),
              const SizedBox(width: 18),
              _summaryBox('Avg. Battery', avgBattery, Icons.battery_full, statusColor(avgBattery, 'battery'), "${avgBattery.toStringAsFixed(1)}%"),
              const SizedBox(width: 18),
              _summaryBox('Avg. Temp', avgTemp, Icons.thermostat, statusColor(avgTemp, 'temp'), "${avgTemp.toStringAsFixed(1)}°C"),
            ],
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Telemetry Alerts (Last scan)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _alertBox(Icons.memory, cpuHigh, Colors.red, 'High CPU'),
                    const SizedBox(width: 17),
                    _alertBox(Icons.battery_alert, batLow, Colors.red, 'Low Battery'),
                    const SizedBox(width: 17),
                    _alertBox(Icons.device_thermostat, tempHigh, Colors.red, 'High Temp'),
                  ])
                ],
              ),
            ),
          ),
          const SizedBox(height: 42),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quick Overview", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text("Total Devices: ${_devices.length}", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("Any issues: ${(cpuHigh + batLow + tempHigh) > 0 ? 'Yes' : 'No'}", style: TextStyle(color: (cpuHigh + batLow + tempHigh) > 0 ? Colors.red : Colors.green)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _summaryBox(String label, double value, IconData icon, Color color, String display) {
    return Expanded(
      child: Card(
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(display, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alertBox(IconData icon, int count, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 14)),
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: TabBar(
            tabs: [
              Tab(text: 'Analytics'),
              Tab(text: 'Details'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }
}
