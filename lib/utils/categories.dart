// lib/utils/categories.dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Categories for Medical Providers.
final List<Map<String, dynamic>> medicalProviderCategories = [
  {
    'title': 'Cough & Cold',
    'description': 'Sneezing, coughing, sore throat, etc.',
    'icon': FontAwesomeIcons.virus,
  },
  {
    'title': 'Urinary Issues',
    'description': 'Pain, frequency, or burning during urination.',
    'icon': FontAwesomeIcons.notesMedical,
  },
  {
    'title': 'Allergies',
    'description': 'Itchy eyes, sneezing, and rashes.',
    'icon': FontAwesomeIcons.wind,
  },
  {
    'title': 'Digestive Issues',
    'description': 'Abdominal pain, diarrhea, or constipation.',
    'icon': FontAwesomeIcons.pills,
  },
  {
    'title': 'Skin Problems',
    'description': 'Skin irritation, redness, or rashes.',
    'icon': FontAwesomeIcons.allergies,
  },
  {
    'title': 'Joint/Muscle',
    'description': 'Joint pain, muscle aches, or stiffness.',
    'icon': FontAwesomeIcons.bone,
  },
  {
    'title': 'General Health',
    'description': 'General health checkup and routine concerns.',
    'icon': FontAwesomeIcons.heartPulse,
  },
  {
    'title': 'Other',
    'description': 'Other symptoms not categorized above.',
    'icon': FontAwesomeIcons.plus,
  },
];

/// Categories for Physical Therapists.
final List<Map<String, dynamic>> physicalTherapistCategories = [
  {
    'title': 'Neck',
    'description': 'Sore or tight neck muscles',
    'icon': FontAwesomeIcons.userInjured,
  },
  {
    'title': 'Lower Back',
    'description': 'Sore or tight low back muscles',
    'icon': FontAwesomeIcons.personWalking,
  },
  {
    'title': 'Shoulder',
    'description': 'Pain in the shoulder area',
    'icon': FontAwesomeIcons.dumbbell,
  },
  {
    'title': 'Elbow',
    'description': 'Pain in the elbow area',
    'icon': FontAwesomeIcons.handFist,
  },
  {
    'title': 'Wrist/Hand',
    'description': 'Pain in the arm and hand',
    'icon': FontAwesomeIcons.hand,
  },
  {
    'title': 'Hip',
    'description': 'Pain in the hip',
    'icon': FontAwesomeIcons.personWalking,
  },
  {
    'title': 'Knee',
    'description': 'Pain in the knee',
    'icon': FontAwesomeIcons.bandage,
  },
  {
    'title': 'Ankle & Foot',
    'description': 'Pain in the leg and foot',
    'icon': FontAwesomeIcons.socks,
  },
];
