# 🚴‍♂️ Echelon Connect

> **Unlock the full potential of your Echelon EX-3 bike without the subscription.**  
> A premium, open-source Android controller built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![Bluetooth](https://img.shields.io/badge/Bluetooth_5.0-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)

---

## 🚀 Overview

**Echelon Connect** is a modern, high-performance dashboard for Echelon fitness bikes. Built to replace the official app's requirement for expensive subscriptions, it communicates directly with your bike over Bluetooth Low Energy (BLE) to provide real-time metrics and resistance control in a stunning, dark-mode interface.

Say goodbye to monthly fees and hello to **complete control**.

## ✨ Features

*   **⚡ Real-Time Metrics**: Instant feedback on **Power (Watts)**, **Cadence (RPM)**, **Resistance**, and **Speed**.
*   **🎛️ Precision Control**: Adjust resistance levels manually or use **Smart Presets** (10, 20, 30) for interval training.
*   **🎨 Premium UI**: Designed with a "Dark Mode First" philosophy using vibrant accents and smooth animations.
*   **🔌 Instant Connection**: Auto-scan and connect to nearby Echelon devices in seconds.
*   **📱 Tablet Optimized**: Responsive grid layout that adapts perfectly to both phones and tablets.
*   **🔒 Local & Private**: Your workout data stays on your device. No cloud accounts, no tracking.

## 📱 Screenshots

| Dashboard | Connection |
|:---:|:---:|
| *(Add Metric View Screenshot)* | *(Add Scan View Screenshot)* |

## 🛠️ Technology Stack

Built with the latest and greatest in the Flutter ecosystem:

*   **Framework**: [Flutter](https://flutter.dev/) (3.x+)
*   **Language**: [Dart](https://dart.dev/)
*   **State Management**: [Riverpod](https://riverpod.dev/) for robust reactive state.
*   **Bluetooth**: [Flutter Blue Plus](https://pub.dev/packages/flutter_blue_plus) for reliable BLE communication.
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

## 🗺️ Roadmap

- [x] Basic BLE Protocol Implementation
- [x] Real-time Metrics Dashboard
- [x] Resistance Control ( Buttons & Presets )
- [ ] Workout Recording & History
- [ ] Third-Party Integration (Strava, Zwift)
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
