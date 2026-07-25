import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import 'package:flutter/foundation.dart';

class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  factory VideoCallService() => _instance;
  VideoCallService._internal();

  Future<void> joinRoom({
    required String roomName,
    required String userName,
    bool isAudioOnly = false,
    bool isVideoMuted = false,
  }) async {
    try {
      final options = JitsiMeetingOptions(
        roomNameOrUrl: roomName,
        subject: "Basira Help Call",
        userDisplayName: userName,
        isAudioOnly: isAudioOnly,
        isVideoMuted: isVideoMuted,
        // Using strings for feature flags to avoid undefined identifier errors
        featureFlags: {
          "welcomepage.enabled": false,
          "resolution": 720,
        },
      );


      debugPrint("Joining Jitsi Room: $roomName");
      await JitsiMeetWrapper.joinMeeting(
        options: options,
        listener: JitsiMeetingListener(
          onOpened: () => debugPrint("Jitsi Opened"),
          onConferenceWillJoin: (url) => debugPrint("Jitsi Will Join: $url"),
          onConferenceJoined: (url) => debugPrint("Jitsi Joined: $url"),
          onConferenceTerminated: (url, error) => debugPrint("Jitsi Terminated: $url, error: $error"),
          onAudioMutedChanged: (isMuted) => debugPrint("Audio Muted: $isMuted"),
          onVideoMutedChanged: (isMuted) => debugPrint("Video Muted: $isMuted"),
          onScreenShareToggled: (participantId, isSharing) => debugPrint("Screen Share: $participantId, $isSharing"),
          onParticipantJoined: (email, name, role, participantId) => debugPrint("Participant Joined: $name"),
          onParticipantLeft: (participantId) => debugPrint("Participant Left: $participantId"),
          onChatMessageReceived: (senderId, message, isPrivate) => debugPrint("Chat Message: $message"),
          onChatToggled: (isOpen) => debugPrint("Chat Toggled: $isOpen"),
          onClosed: () => debugPrint("Jitsi Closed"),
        ),
      );
    } catch (e) {
      debugPrint("Error joining Jitsi room: $e");
    }
  }
}
