import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class PrinterSettingsScreenOld extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreenOld> {
  final List<TextEditingController> _ipControllers =
  List.generate(3, (_) => TextEditingController());
  int _selectedIpIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedIps();
  }

  Future<void> _loadSavedIps() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedIpIndex = prefs.getInt('selected_ip_index') ?? 0;

      for (int i = 0; i < 3; i++) {
        _ipControllers[i].text = prefs.getString('printer_ip_$i') ?? '';
        debugPrint('Loaded printer_ip_$i : ${_ipControllers[i].text}');
      }

      debugPrint('Selected IP index: $_selectedIpIndex');
    });
  }


  Future<void> _saveIps() async {
    final prefs = await SharedPreferences.getInstance();

    for (int i = 0; i < 3; i++) {
      await prefs.setString('printer_ip_$i', _ipControllers[i].text);
    }
    await prefs.setInt('selected_ip_index', _selectedIpIndex);

    setState(() {}); // ADD THIS LINE TO REFRESH THE UI

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Printer IPs saved')),
    );
  }


  Future<void> _printTest() async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);
    final ip = _ipControllers[_selectedIpIndex].text;

    final result = await printer.connect(ip, port: 9100);

    if (result == PosPrintResult.success) {
      printer.setStyles(PosStyles(align: PosAlign.center));
      printer.text(
        'Hello from Flutter!',
        styles: PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      printer.cut();
      printer.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print success!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print: $result')),
      );
    }
  }

  Widget _buildIpField(int index) {
    return Row(
      children: [
        Radio<int>(
          value: index,
          groupValue: _selectedIpIndex,
          onChanged: (value) async {
            setState(() {
              _selectedIpIndex = value!;
            });

            // SAVE SELECTED INDEX IMMEDIATELY
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('selected_ip_index', _selectedIpIndex);
          },
        ),

        Expanded(
          child: TextFormField(
            controller: _ipControllers[index],
            enabled: index == _selectedIpIndex,
            decoration: InputDecoration(
              labelText: 'IP Address ${index + 1}',
              hintText: 'e.g., 192.168.0.${100 + index}',
            ),
            // textInputAction: TextInputAction.done,
            keyboardType:TextInputType.text,
            // keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _ipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // dismiss keyboard
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          /*    appBar: AppBar(
        backgroundColor: Colors.green[500],
        centerTitle: true,
        title: const Text(
          'Printer Settings',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),*/
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildIpField(0),
                _buildIpField(1),
                _buildIpField(2),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saveIps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[300],
                    foregroundColor: Colors.black, // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  ),
                  child: Text('Save IPs'),
                ),

                /*SizedBox(height: 20),
            ElevatedButton(
              onPressed: _printTest,
              child: Text('Print Test'),
            ),*/
              ],
            ),
          ),
        ));
  }
}
