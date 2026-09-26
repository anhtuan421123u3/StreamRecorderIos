import SwiftUI
import LiveVaultDesignSystem

public struct BrowserView: View {
    @StateObject private var viewModel = BrowserViewModel()
    public var onStartDownloadStream: ((StreamMediaInfo) -> Void)?
    
    public init(onStartDownloadStream: ((StreamMediaInfo) -> Void)? = nil) {
        self.onStartDownloadStream = onStartDownloadStream
    }
    
    public var body: some View {
        ZStack {
            LiveVaultColors.darkBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // URL Navigation Bar
                urlBar
                
                // WebView
                WKWebViewRepresentable(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.bottom)
            }
            
            // Toast Notification
            if viewModel.showToast, let stream = viewModel.latestDetectedStream {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "record.circle.fill")
                            .foregroundColor(LiveVaultColors.primaryRed)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live Stream Detected!")
                                .font(LiveVaultTypography.labelLarge)
                                .foregroundColor(LiveVaultColors.textPrimary)
                            Text(stream.streamType.rawValue)
                                .font(LiveVaultTypography.caption)
                                .foregroundColor(LiveVaultColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button("Inspect") {
                            viewModel.showStreamSelectionSheet = true
                        }
                        .font(LiveVaultTypography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LiveVaultColors.indigoPrimary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(LiveVaultColors.darkSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
            }
            
            // Floating Action Button
            if !viewModel.detectedStreams.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.showStreamSelectionSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "video.badge.plus")
                                    .font(.system(size: 16, weight: .bold))
                                Text("\(viewModel.detectedStreams.count) Streams")
                                    .font(LiveVaultTypography.labelMedium)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(LiveVaultColors.primaryRed)
                            .clipShape(Capsule())
                            .shadow(color: LiveVaultColors.primaryRed.opacity(0.4), radius: 8, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            viewModel.onStartDownloadStream = onStartDownloadStream
        }
        .sheet(isPresented: $viewModel.showStreamSelectionSheet) {
            StreamSelectionSheet(viewModel: viewModel)
        }
    }
    
    private var urlBar: some View {
        HStack(spacing: 10) {
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(viewModel.canGoBack ? LiveVaultColors.textPrimary : LiveVaultColors.textMuted)
            }
            .disabled(!viewModel.canGoBack)
            
            Button(action: { viewModel.goForward() }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.canGoForward ? LiveVaultColors.textPrimary : LiveVaultColors.textMuted)
            }
            .disabled(!viewModel.canGoForward)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(LiveVaultColors.textMuted)
                
                TextField("Search or enter web URL", text: $viewModel.urlString, onCommit: {
                    viewModel.loadURL()
                })
                .font(LiveVaultTypography.bodySmall)
                .foregroundColor(LiveVaultColors.textPrimary)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                if viewModel.isLoading {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button(action: { viewModel.reload() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(LiveVaultColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(LiveVaultColors.darkSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(LiveVaultColors.darkSurfaceBorder, lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(LiveVaultColors.darkBg)
    }
}

public struct StreamSelectionSheet: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        NavigationStack {
            ZStack {
                LiveVaultColors.darkBg.ignoresSafeArea()
                
                List {
                    Section {
                        ForEach(viewModel.detectedStreams) { stream in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(stream.streamType.rawValue)
                                        .font(.system(size: 11, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(LiveVaultColors.indigoPrimary.opacity(0.2))
                                        .foregroundColor(LiveVaultColors.indigoSecondary)
                                        .cornerRadius(6)
                                    Spacer()
                                    Text(stream.detectedAt, style: .time)
                                        .font(LiveVaultTypography.caption)
                                        .foregroundColor(LiveVaultColors.textMuted)
                                }
                                
                                Text(stream.title)
                                    .font(LiveVaultTypography.titleSmall)
                                    .foregroundColor(LiveVaultColors.textPrimary)
                                
                                Text(stream.url.absoluteString)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(LiveVaultColors.textMuted)
                                    .lineLimit(1)
                                
                                Button(action: {
                                    viewModel.triggerDownload(stream: stream)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Record / Download Stream")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .foregroundColor(.white)
                                    .background(LiveVaultColors.primaryRed)
                                    .cornerRadius(10)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(LiveVaultColors.darkSurface)
                        }
                    } header: {
                        Text("Detected Live Streams")
                            .foregroundColor(LiveVaultColors.textSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Live Streams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(LiveVaultColors.indigoSecondary)
                }
            }
        }
    }
}