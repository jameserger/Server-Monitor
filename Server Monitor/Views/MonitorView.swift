//
//  Monitor.swift
//  Server Monitor
//
//  Created by Gandalf on 1/31/26.
//

import SwiftUI

struct MonitorView: View {
    @StateObject private var gravyService = GravyService()

    @AppStorage("checkIntervalSeconds") private var checkIntervalSeconds: Double = 3600
    @AppStorage("notifyOnAllGood") private var notifyOnAllGood: Bool = false
    @AppStorage("lastCheckTimestamp") private var lastCheckTimestampStorage: Double = 0

    @State private var isMonitoring = false
    @State private var hasChecked = false
    @State private var isCheckingNow = false
    @State private var monitoringTask: Task<Void, Never>? = nil
    @State private var showBusinessUpdate = false

    private var statusText: String {
        gravyService.isServerHealthy ? "All Good" : "Server Error"
    }

    private var statusColor: Color {
        gravyService.isServerHealthy ? .green : .red
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Gravy Server Monitor")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            VStack {
                Text("Status")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Spacer().frame(height: 20)
                
                VStack(spacing: 6) {
                    
                    Text(isCheckingNow ? "Checking..." : statusText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isCheckingNow ? .secondary : statusColor)
                        .opacity(hasChecked ? 1 : 0)
                    
                    Spacer().frame(height: 10)
                    
                    if hasChecked {
                        Text(lastCheckText)
                            .font(.footnote)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.black, lineWidth: 3))
            

            Spacer()
            
            Toggle("Notify me for All Good", isOn: $notifyOnAllGood)
                .padding(.horizontal)

            Spacer()
            
            VStack(spacing: 8) {
                Text("Check Interval: \(Int(checkIntervalSeconds / 60)) min")

                Stepper(
                    value: Binding(
                        get: { Int(checkIntervalSeconds / 60) },
                        set: { checkIntervalSeconds = Double($0) * 60 }
                    ),
                    in: 1...180
                ) {
                    Text("Minutes")
                }
                .padding(.horizontal)
            }

            Spacer().frame(height: 30)

            Button {
                Task { await checkServerNow() }
            } label: {
                Text("Check Status Now")
                    .fontWeight(.bold)
                    .frame(maxWidth: 300, maxHeight: 20)
                    .padding(12)
                    .foregroundColor(.white)
                    .background(.green)
                    .cornerRadius(80)
            }

            Spacer().frame(height: 20)

            Button {
                toggleMonitoring()
            } label: {
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .fontWeight(.bold)
                    .frame(maxWidth: 300, maxHeight: 20)
                    .padding(12)
                    .foregroundColor(.white)
                    .background(isMonitoring ? .red : .blue)
                    .cornerRadius(80)
            }

            Spacer()
            
            Button {
                showBusinessUpdate = true
            } label: {
                Text("Update Business")
                    .fontWeight(.bold)
                    .frame(maxWidth: 300, maxHeight: 20)
                    .padding(12)
                    .foregroundColor(.white)
                    .background(.blue)
                    .cornerRadius(80)
            }
            
            Spacer()
        }
        .navigationDestination(isPresented: $showBusinessUpdate) {
            BusinessView()
        }        
    }

    private var lastCheckText: String {
        guard lastCheckTimestampStorage > 0 else { return "Never Checked" }

        let date = Date(timeIntervalSince1970: lastCheckTimestampStorage)

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium

        return "Last Checked: \(formatter.string(from: date))"
    }
    
    @MainActor
    private func checkServerNow() async {
        guard !isCheckingNow else { return }
        isCheckingNow = true
        defer {
            isCheckingNow = false
            hasChecked = true
        }

        await gravyService.getPlans()
    }

    @MainActor
    private func toggleMonitoring() {
        if isMonitoring {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }

    @MainActor
    private func startMonitoring() {
        isMonitoring = true
        monitoringTask?.cancel()

        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await checkServerNow()

                let seconds = max(60, checkIntervalSeconds) // clamp >= 1 minute
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
    }

    @MainActor
    private func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}
