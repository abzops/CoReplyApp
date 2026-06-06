# CoReply AI — Premium iOS Keyboard Extension

CoReply AI is a premium iOS AI Keyboard Extension that helps users generate intelligent, context-aware replies inside Snapchat, WhatsApp, Instagram, and other messaging apps without switching applications. 

This repository contains the complete Swift codebase structured with XcodeGen, enabling a **No-Mac Workflow** for compiling and installing on an iPhone directly from a Windows machine.

---

## 🚀 Key Features

* **Instant Clipboard Detection:** Automatically detects copied messages when you open the keyboard.
* **12 Diverse Reply Styles:** Choose from Best, Casual, Funny, Flirty, Romantic, Gen Z (slang), Professional, Savage, Malayalam, Manglish, Continue Conversation, and Rewrite.
* **Contextual Relationship Profiles:** Keep track of who you are talking to (crush, friend, colleague, boyfriend, girlfriend, ex, etc.) and what the current conversation goal is to generate extremely tailored replies.
* **Personality Cloning:** Select or build unique voice personalities (Confident, Romantic, Savage, Malayalam Gen Z, etc.) that shape your generated answers.
* **Direct Insertion:** Insert the chosen reply directly into any chat input box with a single tap.
* **Premium StoreKit 2 Paywall:** Free users have a daily limit of 20 generations, with local Pro/Premium entitlement checking.
* **Secure Keychain Sync:** Stores keys (OpenAI API key, Supabase keys) securely using Apple's Keychain Services.

---

## 🛠️ Tech Stack & Architecture

* **OS Target:** iOS 17.0+ (Swift 5.9 / Xcode 16+)
* **Main App UI:** SwiftUI with vibrant dark mode, glassmorphism, and shimmer animations.
* **Keyboard Extension UI:** UIKit root controller (`KeyboardViewController`) hosting a SwiftUI `KeyboardView` canvas designed for optimal 320pt keyboard layout.
* **Data Sharing:** App Groups Suite (`group.com.abhinand.coreply`) for syncing settings between App and Keyboard.
* **Credentials Sharing:** Secure Keychain Access Group (`com.abhinand.coreply`) for sharing API keys.
* **Backend Database:** Supabase Database (Auth, users, relationship profiles, messages, replies, and usage events logging).
* **AI Engine:** Direct REST API interactions with OpenAI GPT-4o-mini completion endpoints.

---

## ⚡ The "No-Mac" Workflow (100% Free)

You can build, archive, and sideload this application directly using a Windows PC.

```
Your Windows PC ──> Push Code ──> GitHub Private Repo ──> GitHub Actions (macos-15 runner) ──> Download .ipa ──> Sideload (Sideloadly/AltStore) ──> iPhone
```

### Step 1: Push Code to GitHub
1. Create a private repository on GitHub (e.g., `CoReplyApp`).
2. Add the remote and push:
   ```bash
   git remote add origin git@github.com:abzops/CoReplyApp.git
   git branch -M main
   git add .
   git commit -m "Initialize CoReply AI complete Swift project"
   git push -u origin main
   ```

### Step 2: Auto-Build on GitHub Actions
1. Pushing to the `main` or `develop` branch automatically triggers the `.github/workflows/ios.yml` action.
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
1. Open the **CoReply** app on your iPhone.
2. Complete the onboarding questionnaire (stores your preferred texting language and communication style).
3. Go to the **Settings** screen (4th tab):
   - Input your **OpenAI API Key** (create one at [platform.openai.com](https://platform.openai.com)).
   - Input your **Supabase URL** and **Anon Key** (create a free database project at [supabase.com](https://supabase.com)).
   - Click **Save Keys**.
4. Go to **Settings → General → Keyboard → Keyboards** on your iPhone:
   - Tap **Add New Keyboard...** and select **CoReply**.
   - Tap the newly added **CoReply** keyboard in the list and toggle **Allow Full Access** on (this is required to let the keyboard read the pasteboard clipboard and make API network requests).

---

## 🗄️ Supabase Schema Configuration

Create a free project on Supabase and run the SQL queries located in `CoReply/supabase/schema.sql` inside your Supabase SQL Editor. This sets up the following structure:
* `users` - Syncs local app profiles (tier, communication style, etc.)
* `profiles` - Syncs relationship profile cards
* `messages` & `replies` - Logs generated responses for analytics and selection tracking
* `usage_events` - Tracks user app interaction events

---

## 💻 Building Locally on a Mac

If you have a macOS device, you can build locally:
1. Ensure Xcode 16.0+ is installed.
2. Navigate to the project folder:
   ```bash
   cd CoReply
   ```
3. Generate the project using XcodeGen:
   ```bash
   make generate
   ```
4. Open the generated project:
   ```bash
   make open
   ```
5. Run unit tests in simulator:
   ```bash
   make test
   ```
