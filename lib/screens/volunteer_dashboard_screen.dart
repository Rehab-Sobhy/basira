import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/voice_service.dart';
import 'package:vibration/vibration.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  final _supabaseService = SupabaseService();
  final _voiceService = VoiceService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isActive = false;
  bool _isLoading = true;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _loadData();
  }

  Future<void> _togglePhoneVoice() async {
    if (_voiceService.isListening) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
      final digits = _voiceService.extractDigits(_voiceService.lastRecognizedWords);
      if (digits.isNotEmpty) {
        _phoneController.text = digits;
      }
      Vibration.vibrate(duration: 100);
    } else {
      if (!_voiceService.isAvailable) await _voiceService.init();
      setState(() => _isListening = true);
      Vibration.vibrate(duration: 100);
      _voiceService.startListening((text, isFinal) {
        setState(() {}); // Update UI for lastRecognizedWords if needed
      });
    }
  }


  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('vol_name') ?? '';
    _phoneController.text = prefs.getString('vol_phone') ?? '';
    _isActive = prefs.getBool('vol_is_active') ?? false;
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveDataAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vol_name', _nameController.text);
    await prefs.setString('vol_phone', _phoneController.text);
    await prefs.setBool('vol_is_active', _isActive);

    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      try {
        await _supabaseService.updateVolunteerProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          isActive: _isActive,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء الاتصال بالخادم')),
          );
        }
      }
    } else if (_isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال الاسم ورقم الهاتف أولاً')),
        );
        setState(() {
          _isActive = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المتطوع'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.volunteer_activism, size: 80, color: Colors.teal),
              const SizedBox(height: 24),
              Text(
                'بيانات التواصل',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.stop : Icons.mic, color: _isListening ? Colors.red : Colors.teal),
                    onPressed: _togglePhoneVoice,
                  ),
                  helperText: _isListening ? 'أنا أسمعك... المس المربع الأحمر للانتهاء' : null,
                ),
              ),

              const SizedBox(height: 32),
              Card(
                color: _isActive ? Colors.teal.shade50 : Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isActive ? 'أنا متاح للمساعدة' : 'أنا غير متاح الآن',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _isActive ? Colors.teal.shade800 : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Switch(
                        value: _isActive,
                        activeThumbColor: Colors.teal,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                          _saveDataAndSync();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.teal,
                ),
                onPressed: _saveDataAndSync,
                child: const Text(
                  'حفظ البيانات',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
