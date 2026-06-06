# CoReply AI — Premium iOS Keyboard Extension

CoReply AI is a premium iOS AI Keyboard Extension that helps users generate intelligent replies inside Snapchat and other messaging apps without switching applications. 

This repository contains the complete Swift codebase structured with XcodeGen, enabling a **No-Mac Workflow** for compiling and installing on an iPhone.

---

## 🛠️ Tech Stack & Architecture

- **iOS Target**: iOS 17.0+
- **Architecture**: MVVM (Model-View-ViewModel) + Model Store Layer
- **Layout Framework**: SwiftUI (Main App & Keyboard views), UIKit (Extension ViewController)
- **Data Sharing**: App Groups Suite (`group.com.abhinand.coreply`)
- **Credentials Sharing**: Secure Keychain Access Group (`com.abhinand.coreply`)
- **Backend Integrations**: Supabase Database, Auth, Realtime Real-time logs
- **AI Engine**: OpenAI GPT-4o-mini REST completion endpoint
- **Monetization**: StoreKit 2 local entitlements validation

---

## ⚡ The "No-Mac" Workflow (100% Free)

You can build, archive, and sideload this application directly using a Windows PC.

```
Your Windows PC ──> Push Code ──> GitHub Private Repo ──> GitHub Actions (macos-15 runner) ──> Download .ipa ──> Sideload (Sideloadly/AltStore) ──> iPhone
```

### Step 1: Push Code to GitHub
1. Create a private repository on GitHub (e.g., `coreply-ai`).
2. Add your local files to git:
   ```bash
   git init
   git add .
   git commit -m "Initialize CoReply AI complete Swift project"
   git remote add origin https://github.com/your-username/coreply-ai.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Auto-Build on GitHub Actions
1. Pushing to the `main` branch automatically triggers the `.github/workflows/ios.yml` action.
2. The GitHub Actions worker runs a macOS virtual machine to:
   - Install **XcodeGen**.
   - Generate the `CoReply.xcodeproj` project structure.
   - Resolve package dependencies (Supabase, RevenueCat).
   - Compile and build an **unsigned Release IPA**.
3. Once the build completes, download the **`CoReply-unsigned-IPA`** file from the Actions execution summary under the **Artifacts** section.

### Step 3: Install on your iPhone (Sideloading)
1. Download **Sideloadly** (Free for Windows/macOS) from [sideloadly.io](https://sideloadly.io).
2. Connect your iPhone to your Windows PC using a USB cable.
3. Open Sideloadly:
   - Drag and drop the downloaded `CoReply-unsigned.ipa` file into the IPA icon box.
   - Enter your Apple ID (used to self-sign the app for free).
   - Click **Start** to sign and install the app on your phone.
4. On your iPhone:
   - Go to **Settings → General → VPN & Device Management**.
   - Tap your Apple ID and select **Trust**.
   - Enable **Developer Mode** (Settings → Privacy & Security → Developer Mode) and restart your device if prompted.

---

## ⚙️ Initial App Configuration

Once the application is installed on your device, perform the following setup:
1. Open the **CoReply AI** app on your iPhone.
2. Complete the onboarding questionnaire (stores your preferred texting language and communication style).
3. Go to the **Settings** screen (4th tab):
   - Input your **OpenAI API Key** (create one at [platform.openai.com](https://platform.openai.com)).
   - Input your **Supabase URL** and **Anon Key** (create a free database project at [supabase.com](https://supabase.com)).
   - Click **Save Keys**.
4. Go to **Settings → General → Keyboard → Keyboards** on your iPhone:
   - Tap **Add New Keyboard...** and select **CoReply AI**.
   - Tap the newly added **CoReply AI** keyboard in the list and toggle **Allow Full Access** on (this is required to let the keyboard read the pasteboard clipboard and make API network requests).

---

## 💻 Building Locally on a Mac

If you have a macOS device, you can build locally:
1. Ensure Xcode 15.4+ is installed.
2. Generate the project:
   ```bash
   make generate
   ```
3. Open in Xcode:
   ```bash
   make open
   ```
4. Build or run tests:
   ```bash
   make test
   ```
