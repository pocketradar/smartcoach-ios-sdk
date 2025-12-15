@Tutorial(time: 8) {
    @Section(title: "Respond to User Selection") {
        Allow the user to pick a radar from your scan results:
        
        @CodeListing(language: "swift") {
            func userSelectedRadar(_ radar: SmartCoachRadar) async {
            do {
            try await SmartCoach.connect(to: radar)
            } catch {
            print("Connection failed: \\(error)")
            }
            }
            }
            
            @Step {
                Trigger connect(to:) when the user taps a radar in the UI.
                }
                }
                
                @Section(title: "Observe Connection State") {
                    The session state will update:
                    
                    ```
                    .connecting(radar)
                    → .connected(radar)
                    ```
                    
                    @CodeListing(language: "swift") {
                        for await state in try await SmartCoach.sessionStateStream() {
                        switch state {
                        case .connecting(let radar):
                        print("Connecting to \\(radar.id)...")
                        
                        case .connected(let radar):
                        print("Connected to: \\(radar.id)")
                        
                        default:
                        break
                        }
                        }
                        }
                        
                        @Step {
                            Reflect session states in your UI.
                            }
                            }
                            }
