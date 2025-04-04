// lib/utils/categories.dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Categories for Medical Providers.
final List<Map<String, dynamic>> medicalProviderCategories = [
  {
    'title': 'Cough & Cold',
    'description': 'Sneezing, coughing, sore throat, etc.',
    'icon': FontAwesomeIcons.virus,
    'imagePath': 'assets/images/cough_cold.png',
  },
  {
    'title': 'Urinary Issues',
    'description': 'Pain, frequency, or burning during urination.',
    'icon': FontAwesomeIcons.notesMedical,
    'imagePath': 'assets/images/uti.png',
  },
  {
    'title': 'Allergies',
    'description': 'Itchy eyes, sneezing, and rashes.',
    'icon': FontAwesomeIcons.wind,
    'imagePath': 'assets/images/allergies.png',
  },
  {
    'title': 'Digestive Issues',
    'description': 'Abdominal pain, diarrhea, or constipation.',
    'icon': FontAwesomeIcons.pills,
    'imagePath': 'assets/images/gi.png',
  },
  {
    'title': 'Skin Problems',
    'description': 'Skin irritation, redness, or rashes.',
    'icon': FontAwesomeIcons.allergies,
    'imagePath': 'assets/images/skin.png',
  },
  {
    'title': 'Joint/Muscle',
    'description': 'Joint pain, muscle aches, or stiffness.',
    'icon': FontAwesomeIcons.bone,
    'imagePath': 'assets/images/msk.png',
  },
  {
    'title': 'General Health',
    'description': 'General health checkup and routine concerns.',
    'icon': FontAwesomeIcons.heartPulse,
    'imagePath': 'assets/images/general.png',
  },
  {
    'title': 'Other Health',
    'description': 'Other symptoms not categorized above.',
    'icon': FontAwesomeIcons.plus,
    'imagePath': 'assets/images/other.png',
  },
];

/// Categories for Physical Therapists.
final List<Map<String, dynamic>> physicalTherapistCategories = [
  {
    'title': 'Neck',
    'description': 'Sore or tight neck muscles',
    'icon': FontAwesomeIcons.userInjured,
    'imagePath': 'assets/images/neck.png',
  },
  {
    'title': 'Lower Back',
    'description': 'Sore or tight low back muscles',
    'icon': FontAwesomeIcons.personWalking,
    'imagePath': 'assets/images/back.png',
  },
  {
    'title': 'Shoulder',
    'description': 'Pain in the shoulder area',
    'icon': FontAwesomeIcons.dumbbell,
    'imagePath': 'assets/images/shoulder.png',
  },
  {
    'title': 'Elbow',
    'description': 'Pain in the elbow area',
    'icon': FontAwesomeIcons.handFist,
    'imagePath': 'assets/images/elbow.png',
  },
  {
    'title': 'Wrist/Hand',
    'description': 'Pain in the arm and hand',
    'icon': FontAwesomeIcons.hand,
    'imagePath': 'assets/images/wrist.png',
  },
  {
    'title': 'Hip',
    'description': 'Pain in the hip',
    'icon': FontAwesomeIcons.personWalking,
    'imagePath': 'assets/images/hip.png',
  },
  {
    'title': 'Knee',
    'description': 'Pain in the knee',
    'icon': FontAwesomeIcons.bandage,
    'imagePath': 'assets/images/knee.png',
  },
  {
    'title': 'Ankle & Foot',
    'description': 'Pain in the leg and foot',
    'icon': FontAwesomeIcons.socks,
    'imagePath': 'assets/images/foot.png',
  },
];
