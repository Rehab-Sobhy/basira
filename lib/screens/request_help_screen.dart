import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/video_call_service.dart';
import '../services/voice_service.dart';

class RequestHelpScreen extends StatefulWidget {
  const RequestHelpScreen({super.key});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}


class _RequestHelpScreenState extends State<RequestHelpScreen> {
  final _supabaseService = SupabaseService();
  final _tts = TtsService();
  final _voiceService = VoiceService();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isRequesting = false;
  bool _requestSent = false;
  bool _volunteerAccepted = false;
  bool _isSelectingType = false;
  bool _isVideo = false;
  String _phoneNumber = '';
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('blind_user_phone') ?? '';
    setState(() {
      _phoneNumber = saved;
      _phoneController.text = saved;
      _isLoading = false;
    });

    if (saved.isNotEmpty) {
      _tts.speak("مرحباً. هل تريد طلب مساعدة؟");
    }
  }

  Future<void> _savePhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 8) {
      _tts.speak("الرقم قصير جداً. يرجى إدخال رقم هاتف صحيح.");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('blind_user_phone', digits);
    setState(() {
      _phoneNumber = digits;
      _phoneController.text = digits;
    });
    Vibration.vibrate(duration: 200);
    _tts.speak("تم حفظ الرقم $digits بنجاح.");
    _promptForType();
  }

  void _clearPhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('blind_user_phone');
    setState(() {
      _phoneNumber = '';
      _phoneController.clear();
      _requestSent = false;
      _volunteerAccepted = false;
      _isSelectingType = false;
    });
    _tts.speak("تم مسح الرقم. يرجى إدخال رقم جديد.");
  }

  void _promptForType() {
    setState(() => _isSelectingType = true);
    _tts.speak("اختر نوع المساعدة. الجزء العلوي فيديو، والأسفل صوت فقط.");
  }

  Future<void> _submitRequest({required bool isVideo}) async {
    setState(() {
      _isVideo = isVideo;
      _isSelectingType = false;
      _isRequesting = true;
    });

    try {
      await _supabaseService.createHelpRequest(_phoneNumber, isVideo: isVideo);

      setState(() {
        _requestSent = true;
        _isRequesting = false;
      });

      Vibration.vibrate(pattern: [0, 500, 100, 500]);
      _tts.speak("تم إرسال طلبك. انتظر اتصال المتطوع.");
      _startTrackingStatus();
    } catch (e) {
      setState(() => _isRequesting = false);
      _tts.speak("فشل الإرسال. الخطأ هو: ${e.toString()}");
      debugPrint("Help Request Error: $e");
    }

  }

  void _startTrackingStatus() {
    _statusSubscription = _supabaseService.streamMyRequests().listen((requests) {
      if (requests.isNotEmpty) {
        final latest = requests.first;
        if (latest['status'] == 'accepted' && !_volunteerAccepted) {
          setState(() => _volunteerAccepted = true);
          Vibration.vibrate(duration: 1000);
          
          _tts.speak("لقد قبل متطوع طلبك. هل تريد فتح المكالمة؟ قل 'افتح' أو 'موافق' أو المس الشاشة.");
          
          // Start voice recognition to listen for "Open" or "Agree"
          _listenForCallAcceptance(latest);
        }
      }
    });
  }

  Future<void> _listenForCallAcceptance(Map<String, dynamic> request) async {
    bool initialized = await _voiceService.init();
    if (initialized) {
      _voiceService.startListening((text, isFinal) {
        final lowerText = text.toLowerCase();
        if (lowerText.contains('افتح') || 
            lowerText.contains('موافق') || 
            lowerText.contains('نعم') ||
            lowerText.contains('open') || 
            lowerText.contains('agree') || 
            lowerText.contains('accept')) {
          _voiceService.stopListening();
          _joinCall(request);
        }
      });
    }
  }

  void _joinCall(Map<String, dynamic> request) {
    final videoCallService = VideoCallService();
    if (request['is_video'] == true) {
      final roomName = "nour_help_room_${request['id']}";
      videoCallService.joinRoom(roomName: roomName, userName: "Blind User");
    } else {
      _tts.speak("سيتصل بك المتطوع على رقمك قريباً.");
    }
  }

  // ─────────────── BUILD ───────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            _tts.speak("العودة للخلف");
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(

        child: _requestSent
            ? _buildSuccessView()
            : _isSelectingType
                ? _buildTypeSelectionView()
                : _phoneNumber.isEmpty
                    ? _buildPhoneSetupView()
                    : _buildReadyView(),
      ),
    );
  }

  // ── 1. Phone Setup (first time) ──
  Widget _buildPhoneSetupView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.phone_android, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'إعداد رقم الهاتف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'هذه الخطوة تتم مرة واحدة فقط. يقوم شخص مبصر بإدخال رقم هاتف الكفيف حتى يتمكن المتطوعون من الاتصال به.',
            style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 48),
          // Phone field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLength: 15,
            decoration: InputDecoration(
              counterText: '',
              hintText: '05xxxxxxxx',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 24, letterSpacing: 2),
              prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent, size: 28),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            ),
            onSubmitted: _savePhone,
          ),
          const SizedBox(height: 32),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton.icon(
              onPressed: () => _savePhone(_phoneController.text),
              icon: const Icon(Icons.check_circle, size: 28),
              label: const Text(
                'حفظ الرقم والمتابعة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Ready View (phone saved) ──
  Widget _buildReadyView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top bar with phone info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, color: Colors.greenAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _phoneNumber,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
                IconButton(
                  onPressed: _clearPhone,
                  icon: const Icon(Icons.edit, color: Colors.white54, size: 22),
                  tooltip: 'تغيير الرقم',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_isRequesting)
            const Expanded(
              child: Center(child: SpinKitDoubleBounce(color: Colors.blueAccent, size: 100)),
            )
          else ...[
            const Spacer(),
            const Icon(Icons.support_agent, color: Colors.blueAccent, size: 100),
            const SizedBox(height: 24),
            const Text(
              'جاهز لطلب المساعدة',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'اضغط الزر أدناه لطلب مساعدة متطوع',
              style: TextStyle(color: Colors.white60, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: _promptForType,
                icon: const Icon(Icons.waving_hand, size: 32),
                label: const Text(
                  'اطلب مساعدة الآن',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ── 3. Type Selection (video/voice) ──
  Widget _buildTypeSelectionView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('اختر نوع المساعدة',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_phoneNumber,
                style: const TextStyle(color: Colors.white54, fontSize: 18, letterSpacing: 2),
              ),
            ],
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.blue.shade700,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              onTap: () => _submitRequest(isVideo: true),
              child: const SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, size: 100, color: Colors.white),
                    SizedBox(height: 12),
                    Text('مكالمة فيديو',
                      style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Material(
            color: Colors.teal.shade600,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              onTap: () => _submitRequest(isVideo: false),
              child: const SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_in_talk, size: 100, color: Colors.white),
                    SizedBox(height: 12),
                    Text('مكالمة صوتية',
                      style: TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. Success / Waiting View ──
  Widget _buildSuccessView() {
    return GestureDetector(
      onTap: () {
        if (_volunteerAccepted) {
          _voiceService.stopListening();
          _supabaseService.streamMyRequests().first.then((requests) {
            if (requests.isNotEmpty) {
              _joinCall(requests.first);
            }
          });
        }
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _volunteerAccepted
                  ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 150)
                  : const SpinKitRipple(color: Colors.greenAccent, size: 180),
              const SizedBox(height: 32),
              Text(
                _volunteerAccepted ? 'متطوع قبل طلبك!' : 'جاري البحث عن متطوع...',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _volunteerAccepted
                    ? (_isVideo ? 'المس الشاشة أو قل "افتح" لبدء المكالمة.' : 'سيتصل بك المتطوع على رقمك.')
                    : 'تم إرسال طلبك.\nسيتصل بك أحد المتطوعين قريباً.',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
