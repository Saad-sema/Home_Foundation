<div align="center">
  <h1>🏠 Home Foundation Management System</h1>
  <p>
    <strong>A Comprehensive Food Distribution & Member Management Platform</strong>
  </p>
  <br />
</div>

## 📖 Overview

The **Home Foundation Management System** is a robust, full-stack application designed to streamline the operations of charitable distributions, specifically focusing on food and ration distribution. It empowers administrators and on-ground staff to track member details, manage claims, and verify identities seamlessly using modern QR code technology.

This project couples a **high-performance Flutter mobile application** with a **secure PHP/MySQL backend**, ensuring reliable data synchronization, conflict checking, and easy generation of reports.

---

## ✨ Key Features

### 📱 Mobile Application (Flutter)
- **QR Code Scanning & Generation:** Instantly verify members via built-in QR scanning utilizing `mobile_scanner`, and dynamically generate new member cards using `qr_flutter`.
- **Distribution Tracking:** Real-time checking of member claim status to prevent duplicate distributions.
- **Member Management:** Edit member records, update contact info, map Aadhar/Ration cards, and flag member consistency directly from the app.
- **Reporting & Exporting:** Generate PDF reports of distribution metrics `printing` and `pdf` packages, or export records to Excel using `excel`.
- **Easy Sharing:** Seamless dissemination of generated member cards and reports via `share_plus`.

### ⚙️ Backend API (PHP)
- **RESTful Architecture:** Lightweight, responsive PHP scripts serving as the communication bridge.
- **Conflict Resolution:** Built-in safeguards preventing duplicate Ration Card assignments and invalid QR operations.
- **Timezone Awareness:** Enforced timezone (IST) setups to securely log `claimed_at` timestamps.
- **Scalable Data Structure:** Relational MySQL database holding structured records for members, distributions, claims, and administrative data.

---

## 🛠️ Technology Stack

| Component | Technology | Description |
|-----------|------------|-------------|
| **Frontend** | Flutter, Dart | Cross-platform mobile development framework |
| **Backend** | PHP 8.x | Lightweight, script-based REST APIs |
| **Database** | MySQL | Highly relational data storage |
| **Server** | Apache (XAMPP/LAMP) | Local backend simulation and hosting |

---

## 🚀 Getting Started

To get a local copy of this project up and running smoothly, follow these steps.

### Prerequisites
- **Flutter SDK** (`>=3.3.0 <4.0.0`)
- **PHP Environment:** XAMPP / WAMP / LAMP Stack
- **Database:** MySQL Server
- **Git**

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Saad-sema/Home_Foundation.git
   cd Home_Foundation
   ```

2. **Database Setup:**
   - Launch your MySQL service (e.g., via XAMPP control panel).
   - Create a new database named `home_foundation` or the appropriate name specified in `config.php`.
   - Import the provided SQL dump `final_home_foundation.sql`:
     ```bash
     mysql -u root -p home_foundation < final_home_foundation.sql
     ```

3. **Backend API Configuration:**
   - Navigate to the `foundationApi` directory.
   - Host this folder in your local server's root (e.g., `htdocs` for XAMPP).
   - Ensure the IP mapping points correctly. Update `foundationApi/config.php` with your local database credentials if they differ from the default.

4. **Flutter App Setup:**
   - Open the terminal and navigate to the application folder.
   - Get the required dependencies:
     ```bash
     cd maniarfoundation
     flutter pub get
     ```
   - Make sure your API URL matches the local IPv4 address mapped to your server (within the Dart API service files).
   - Run the application:
     ```bash
     flutter run
     ```

---

## 📂 Repository Structure

```text
Home_Foundation/
├── final_home_foundation.sql   # Complete database schema and initial data setup
├── foundationApi/              # PHP Backend API Endpoints (CRUD operations, logic)
│   ├── checkClaim.php          # Validates if a user has already claimed their item
│   ├── updateMember.php        # Core logic for updating user details securely
│   └── ...                     # (Multiple endpoint scripts)
└── maniarfoundation/           # Flutter Mobile Application Source Code
    ├── lib/                    # Main Dart codebase
    ├── pubspec.yaml            # Flutter app configuration and dependencies
    └── assets/                 # App icons, logos, and required media
```

---

## 🛡️ Best Practices & Security

- All API endpoints validate explicitly formatted POST/GET payload combinations.
- Implemented `Access-Control-Allow-Origin` & robust OPTIONS preflight checks for secure network routing.
- Timezone overrides built directly at the query execution level to circumvent server clock misconfiguration.

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License & Credits

This project was built to empower charity groups and streamline philanthropic efforts. All dependencies utilized retain their original open-source licenses.
