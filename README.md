# 🚴‍♂️ Echelon Connect

> **Unlock the full potential of your Echelon EX-3 bike without the subscription.**  
> A premium, open-source Android controller built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![Bluetooth](https://img.shields.io/badge/Bluetooth_5.0-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)

---

## 🚀 Overview

**Echelon Connect** is a modern, high-performance dashboard for Echelon fitness bikes. Built to replace the official app's requirement for expensive subscriptions, it communicates directly with your bike over Bluetooth Low Energy (BLE) to provide real-time metrics and resistance control in a stunning, dark-mode interface.

Say goodbye to monthly fees and hello to **complete control**.

## ✨ Features

### Core Metrics & Controls
*   **⚡ Real-Time Metrics**: Instant feedback on **Power (Watts)**, **Cadence (RPM)**, **Resistance**, and **Speed**.
*   **🎛️ Precision Control**: Adjust resistance levels manually with +/- buttons or use **Smart Presets** (10, 20, 30) for quick interval training adjustments.
*   **📊 Peloton Resistance %**: Resistance values are displayed as Peloton-compatible percentages for easy cross-platform workout following.

### Structured Workouts
*   **🏋️ Pre-Built Workout Programs**: Choose from 5 professionally designed workout styles:
    - ⭐ **Interval Training** - High-intensity intervals with recovery periods
    - ⛰️ **Hill Climb** - Progressive resistance increases simulating hill climbs  
    - 🔥 **Tabata Sprints** - Classic 20/10 HIIT intervals for maximum calorie burn
    - 🌊 **Rolling Hills** - Simulated terrain with peaks and valleys
    - 💪 **Power Pyramid** - Build up to peak resistance then descend
*   **📈 Difficulty Variations**: Each workout style includes **Easy**, **Medium**, and **Hard** difficulty levels to match your fitness.
*   **🎯 Target Cadence**: Each workout step includes target cadence guidance to keep you in the optimal training zone.
*   **⏱️ Auto-Resistance**: Workouts automatically adjust your bike's resistance as you progress through each step.
*   **⏩ Workout Controls**: Pause, resume, skip steps, or end workouts early with intuitive controls.

### Android Picture-in-Picture (PiP)
*   **📱 Compact PiP Mode**: Continue monitoring your workout while using other apps with an always-on-top overlay showing:
    - Cadence (RPM)
    - Speed (MPH)
    - Peloton Resistance %

### Theme Support
*   **🌙 Dark Mode**: Premium dark theme as the default for comfortable low-light workouts.
*   **☀️ Light Mode**: Toggle to light theme for bright environments via the theme switch in the app header.

### Design & UX
*   **🎨 Premium UI**: Designed with a "Dark Mode First" philosophy using vibrant accents, glassmorphism, and smooth animations.
*   **📱 Tablet Optimized**: Responsive grid layout that adapts perfectly to both phones and tablets (optimized for Kindle Fire 10" landscape).
*   **🔒 Local & Private**: Your workout data stays on your device. No cloud accounts, no tracking.
*   **🔌 Instant Connection**: Auto-scan and connect to nearby Echelon devices in seconds.

## 📱 Screenshots

| Dashboard | Workout Styles | Active Workout |
|:---:|:---:|:---:|
| *(Metric View)* | *(Style Selection)* | *(In-Progress Workout)* |

## 🛠️ Technology Stack

Built with the latest and greatest in the Flutter ecosystem:

*   **Framework**: [Flutter](https://flutter.dev/) (3.x+)
*   **Language**: [Dart](https://dart.dev/)
*   **State Management**: [Riverpod](https://riverpod.dev/) for robust reactive state.
*   **Bluetooth**: [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus) for reliable BLE communication.
*   **Local Storage**: [Hive](https://pub.dev/packages/hive) for fast, lightweight local persistence.
*   **Picture-in-Picture**: [Android PiP](https://pub.dev/packages/android_pip) for multitasking overlay.
*   **Typography**: [Google Fonts](https://fonts.google.com/) (Inter).

## 🏁 Getting Started

### Prerequisites

*   Flutter SDK installed ([Guide](https://docs.flutter.dev/get-started/install))
*   Android Studio / VS Code
*   An Android device with Bluetooth support (Simulator does not support Bluetooth)

### Installation

1.  **Clone the repository**
    ```bash
    git clone git@github.com:CodeMasterGohan/echelon-connect.git
    cd echelon-connect
    ```

2.  **Get dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the app**
    Connect your Android device and run:
    ```bash
    flutter run
    ```

4.  **Build APK** (optional)
    ```bash
    flutter build apk --debug
    ```

## 🗺️ Roadmap

- [x] Basic BLE Protocol Implementation
- [x] Real-time Metrics Dashboard
- [x] Resistance Control (Buttons & Presets)
- [x] Peloton Resistance % Display
- [x] Structured Workouts with Auto-Resistance
- [x] Workout Difficulty Variations (Easy/Medium/Hard)
- [x] Target Cadence Guidance
- [x] Android Picture-in-Picture Mode
- [x] Dark/Light Theme Toggle
- [ ] Workout Recording & History
- [ ] Third-Party Integration (Strava Export)
- [ ] Graph Visualization

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
  Built with ❤️ by CodeMasterGohan
</p>
