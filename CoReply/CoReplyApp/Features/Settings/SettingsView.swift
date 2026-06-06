// SettingsView.swift
// CoReply
//
// Application settings panels for credentials, keyboard setups and safety controls.

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showResetAlert = false
    @State private var isKeySecure = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                DesignConstants.Gradients.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignConstants.Spacing.lg) {
                        
                        // API KEYS Section
                        credentialsSection
                        
                        // KEYBOARD INSTRUCTIONS
                        keyboardSetupCard
                        
                        // PREFERENCES Section
                        preferencesSection
                        
                        // DANGER ZONE Section
                        dangerZoneSection
                        
                        // Version
                        VStack(spacing: 4) {
                            Text("CoReply AI v1.0.0 (Build 1)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(DesignConstants.Colors.textMuted)
                            
                            Text("Made with ❤️ for Snapchat users")
                                .font(.system(size: 10))
                                .foregroundColor(DesignConstants.Colors.textMuted)
                        }
                        .padding(.vertical, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Settings")
            .alert("Delete All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete everything", role: .destructive) {
                    viewModel.deleteAllData()
                }
            } message: {
                Text("This action cannot be undone. It will clear all credentials, profiles, active personalities, and custom history items.")
            }
            .onAppear {
                viewModel.loadKeys()
            }
        }
    }
    
    // MARK: - Credentials Section
    
    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                Text("API Keys Setup")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                // OpenAI API Key
                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenAI API Key")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                    
                    HStack {
                        if isKeySecure {
                            SecureField("sk-...", text: $viewModel.openAIKey)
                                .foregroundColor(.white)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            TextField("sk-...", text: $viewModel.openAIKey)
                                .foregroundColor(.white)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        Button {
                            isKeySecure.toggle()
                        } label: {
                            Image(systemName: isKeySecure ? "eye.slash" : "eye")
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                }
                
                // Supabase URL
                VStack(alignment: .leading, spacing: 6) {
                    Text("Supabase URL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                    
                    TextField("https://...", text: $viewModel.supabaseURL)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                }
                
                // Supabase Anon Key
                VStack(alignment: .leading, spacing: 6) {
                    Text("Supabase Anon Key")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignConstants.Colors.textSecondary)
                    
                    TextField("eyJhbGci...", text: $viewModel.supabaseAnonKey)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                }
            }
            
            HStack(spacing: 12) {
                // Clear button
                Button {
                    viewModel.clearAPIKeys()
                } label: {
                    Text("Clear Keys")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                }
                
                // Save button
                Button {
                    viewModel.saveAPIKeys()
                } label: {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else if viewModel.saveSuccess {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                        } else {
                            Text("Save Keys")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.saveSuccess ? DesignConstants.Colors.success : DesignConstants.Colors.primaryAccent)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSaving)
            }
            .padding(.top, 4)
        }
        .padding()
        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
        .padding(.horizontal)
    }
    
    // MARK: - Keyboard Setup Instructions Card
    
    private var keyboardSetupCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "keyboard.fill")
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                Text("Enable Keyboard Extension")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                instructionRow(num: "1", text: "Open system Settings application.")
                instructionRow(num: "2", text: "Navigate to General → Keyboard → Keyboards.")
                instructionRow(num: "3", text: "Tap 'Add New Keyboard' and select 'CoReply AI'.")
                instructionRow(num: "4", text: "Tap CoReply in list and toggle 'Allow Full Access' to read clipboard.")
            }
            .padding(.vertical, 4)
            
            Button {
                viewModel.openSystemKeyboardSettings()
            } label: {
                HStack {
                    Text("Open Keyboard Settings")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "arrow.up.forward.app.fill")
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(DesignConstants.Colors.primaryAccent.opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignConstants.Colors.primaryAccent.opacity(0.4), lineWidth: 1)
                )
            }
        }
        .padding()
        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
        .padding(.horizontal)
    }
    
    private func instructionRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(num)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(DesignConstants.Colors.primaryAccent.opacity(0.2))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(DesignConstants.Colors.textSecondary)
                .lineSpacing(2)
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(DesignConstants.Colors.primaryAccent)
                Text("Preferences")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Toggle("Sync via Supabase Cloud", isOn: $viewModel.cloudSyncEnabled)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .tint(DesignConstants.Colors.primaryAccent)
                .onChange(of: viewModel.cloudSyncEnabled) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "cloud_sync_enabled")
                }
        }
        .padding()
        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
        .padding(.horizontal)
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(DesignConstants.Colors.danger)
                Text("Danger Zone")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete All Application Data")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(DesignConstants.Colors.danger.opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignConstants.Colors.danger.opacity(0.4), lineWidth: 1)
                )
            }
        }
        .padding()
        .glassMorphism(cornerRadius: DesignConstants.Radius.medium)
        .padding(.horizontal)
    }
}
