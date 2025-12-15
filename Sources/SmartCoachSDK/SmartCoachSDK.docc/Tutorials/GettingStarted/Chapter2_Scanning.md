@Tutorial(time: 10) {
    @Section(title: "Start Scanning") {
        Use the following to start scanning:
        
        @CodeListing(language: "swift") {
            try await SmartCoach.startScanning()
            }
            
            @Step {
                Call startScanning() from your view model or controller.
                }
                }
                
                @Section(title: "Observe Scanning Results") {
                    Listen to sessionStateStream():
                    
                    @CodeListing(language: "swift") {
                        for await state in try await SmartCoach.sessionStateStream() {
                        if case let .scanning(radars) = state {
                        // Update your UI list
                        }
                        }
                        }
                        
                        @Step {
                            Update your UI whenever .scanning emits new radars.
                            }
                            }
                            
                            @Section(title: "Optional: Enable AutoConnect") {
                                AutoConnect attempts to reconnect to the **last known device**:
                                
                                ```swift
                                try await SmartCoach.startScanning(autoConnect: true)
                                ```
                                
                                @Step {
                                    Enable autoConnect if you want to reconnect quickly in future sessions.
                                    }
                                    }
                                    }
