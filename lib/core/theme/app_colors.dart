import 'package:flutter/material.dart';

class AppColors {
  // Primary Tactical Command Palettes
  static const Color darkBackground = Color(0xFF0A0F1D);      // Deep space navy
  static const Color surface = Color(0xFF131C31);             // Dark tactical navy container
  static const Color surfaceLight = Color(0xFF1E2A45);        // Elevated card surface
  static const Color surfaceBorder = Color(0xFF2B3A5C);       // Muted tactical border
  static const Color charcoal = Color(0xFF161F30);            // Slate charcoal

  // Accents
  static const Color cyan = Color(0xFF00E5FF);                // Electric Cyan (Primary active)
  static const Color cyanDim = Color(0xFF0093A8);             // Dim cyan for inactive states
  static const Color blueAccent = Color(0xFF3A86FF);          // Mission telemetry blue
  
  // Status Colors
  static const Color greenOnline = Color(0xFF00F59B);         // High-vis emerald (active/connected)
  static const Color redEmergency = Color(0xFFFF2A55);        // High-vis tactical red (SOS / alert)
  static const Color orangeWarning = Color(0xFFFF9E00);       // High-vis amber warning (weak link/delay)
  static const Color yellowNote = Color(0xFFFFD166);          // Tactical marker yellow
  static const Color purpleRelay = Color(0xFF9D4EDD);         // Multi-hop relay indicator
  static const Color greyOffline = Color(0xFF6C7A9C);         // Inactive / disconnected grey

  // Typography Colors
  static const Color textPrimary = Color(0xFFF0F4FF);         // Crisp off-white
  static const Color textSecondary = Color(0xFFA2B4D6);       // Tactical slate grey
  static const Color textMuted = Color(0xFF5E7199);           // De-emphasized metadata grey
  static const Color textCyan = Color(0xFF00E5FF);            // Highlighted readout

  // Badges & Gradients
  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFFF2A55), Color(0xFFB5173B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeHeaderGradient = LinearGradient(
    colors: [Color(0xFF131C31), Color(0xFF0F2B48)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cyanGlowGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF3A86FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

