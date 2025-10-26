// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';

import 'colors.dart';

const String supabaseAnonKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvb2t1cHlpbmtpdnRqcnF6b3p3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MzQ0MjcsImV4cCI6MjA3NjExMDQyN30.3P2AI6D_OQPXKp6hxqk5dHiKOz0t4pUk6u1UJDiFg8g";
const String appsScriptSyncId =
    'AKfycbwB-_nLXhh44QaVYP_Jq-mCAGNzp2knuPrEXGAeuoM3LmHV0Jo1A3Rr0RQSShDwPKjwhA';
const String appsScriptSecretKey = '5QHR8InnFUzehNzVdylc59OdTRcGsYyz';
const String adminEmail = 'rafik.gharbi.icloud@gmail.com';

const String defaultPrefix = '+216';
const String defaultIsoCode = 'TN';

BorderRadius circularRadius = BorderRadius.circular(50);
BorderRadius regularRadius = BorderRadius.circular(20);
BorderRadius smallRadius = BorderRadius.circular(10);

Border lightBorder = Border.all(color: kNeutralLightColor, width: 0.5);
Border regularBorder = Border.all(color: kNeutralColor, width: 0.8);
Border regularErrorBorder = Border.all(color: kErrorColor, width: 0.8);

const String phoneRegex = r'^(?:[+0][1-9])?[0-9]{10,12}$';

const double kMinPriceRange = 20;
const double kMaxPriceRange = 2200;

// Define when screens adabt Mobile version UI
const double kMobileMaxWidth = 500;

const int kLoadMoreLimit = 9;
const minPasswordNumberOfCharacters = 3;
