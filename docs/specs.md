# Detailed functional and technical specifications 

## 1. Functional Specification

### 1.1 App Overview

The application is a standalone, client-side mobile and web productivity tool. It acts as a gamified reward system where users manually trigger a monster's evolution after completing real-world tasks. The core loop consists of pressing a button, witnessing a dramatic evolution (visual and audio feedback), and waiting through a mandatory cooldown period.

### 1.2 User Stories

* **As a user**, I want to see my current monster on the main screen so that I know my current progress.
* **As a user**, I want to press an "Evolve" button after I finish a real-life task so that I feel rewarded.
* **As a user**, I want to see a dramatic animation and hear a sound effect when the monster evolves so that the reward feels satisfying and triggers dopamine.
* **As a user**, I want the button to be disabled for exactly 1 minute after pressing it so that I cannot spam the button and cheat the reward system.
* **As a user**, I want my monster's evolution stage to be saved automatically, so I don't lose progress if I close the app.
* **As a user**, I want the app to reset or offer a prestige option once I hit the final stage (Stage 50), so I can start the cycle over.

### 1.3 Core Features & Mechanics

* **Evolution Stages:** 50 distinct stages of the monster.
* **Cooldown Lockout:** A strict 60-second timer. The UI must clearly indicate how much time is left before the button becomes active again (e.g., a countdown text or a grayed-out button).
* **Persistent State:** The app must remember the current evolution stage (1–50) and the exact timestamp of the last button press.
* **Visual/Audio Feedback:** A flash, shake, or particle effect upon pressing the button, accompanied by a satisfying sound effect.
* **Parental Lock (optional, default off):** A grown-up gate on the evolution approval. When enabled (toggle in the users sheet), pressing "I'M READY!" opens a kid-friendly "Ask a grown-up!" dialog and the evolution only proceeds after the correct 4-digit parent PIN. The PIN is stored as a salted SHA-256 hash in local storage; five wrong tries lock the keypad for 30 seconds. This is friction against self-certified rewards, not security — clearing site data clears the lock. Biometric approval (fingerprint via `local_auth`) is a planned enhancement for the mobile builds; the check is isolated in `ParentGate` so it can slot in without touching the flow.

### 1.4 User Interface (UI) Layout

* **Header:** Simple title (e.g., "Task Monster").
* **Center Stage:** A large, prominent image of the monster at its current stage.
* **Action Area:** A prominent, central "Evolve" button.
* **Feedback Area:** A visual timer or progress bar below or on the button showing the 1-minute cooldown.
* **Stage Tracker:** A small text indicator (e.g., "Stage 4"). The total is deliberately not shown so the ladder feels endless.

---

## 2. Technical Specification

### 2.1 Architecture & Tech Stack

* **Framework:** Flutter (Dart).
* **Deployment Targets:** Android (APK/AAB), iOS, and Flutter Web.
* **Architecture:** 100% Client-side. No backend server, APIs, or external databases are required. All assets will be bundled directly into the application.
* **Freshness & offline:** Hosting serves everything with `Cache-Control: no-cache`; a custom **network-first** service worker (`web/flutter_service_worker.js`, builds use `--pwa-strategy=none`) mirrors responses into a cache so the app launches offline with the last-seen version, while online loads always get the latest deploy. The app also polls `version.json` and shows an in-app "new version" prompt for long-lived tabs.

### 2.2 Data Models & State Management

You will need a lightweight state management solution (like `Provider` or Flutter's built-in `ValueNotifier`) to track two main variables:

1. `currentStage` (Integer: 1 to 50).
2. `lastEvolutionTime` (DateTime: The exact moment the button was last pressed).

### 2.3 Core Logic & Algorithms

* **Evolution Logic:**
* On button press -> Increment `currentStage` by 1.
* If `currentStage` == 50 -> Trigger final animation. Next press resets `currentStage` to 1.


* **Timer Logic (Crucial for Mobile):** * *Do not rely solely on a running background timer*, as mobile operating systems suspend apps in the background.
* Instead, on button press, save the current `DateTime.now()` to local storage.
* Whenever the app is opened or resumed, calculate the difference between `DateTime.now()` and the saved timestamp. If the difference is less than 60 seconds, keep the button disabled and start a local UI timer for the remaining seconds.



### 2.4 Asset Management

* **Images:** Monster stages are rendered as emoji (50 distinct emoji in `lib/data/stages.dart`) rather than bundled image files; `assets/images/` holds only branding (the app-bar logo).
* **Audio:** 1 short `.mp3` or `.wav` file stored in the `assets/audio/` directory.

### 2.5 Required Flutter Packages (Dependencies)

To implement this in Flutter, you will add the following packages to your `pubspec.yaml` file:

* `shared_preferences`: To save the `currentStage` and `lastEvolutionTime` locally on the device.
* `audioplayers`: To handle playing the evolution sound effect without latency.
* `flutter_animate` (Optional but highly recommended): A library that makes adding "dramatic" flashes, shakes, and scaling effects to your monster image incredibly easy with just a few lines of code.

### 2.6 Edge Cases to Handle

* **App closed during cooldown:** Handled by the timestamp check on app initialization.
* **Rapid double-tapping:** The button must instantly disable on the first register of a tap to prevent advancing two stages at once.
* **Missing audio permissions (Web):** Browsers block auto-playing audio, but since your audio is triggered by a direct user interaction (a button press), it will function perfectly.
