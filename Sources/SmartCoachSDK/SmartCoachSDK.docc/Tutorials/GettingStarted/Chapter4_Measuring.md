@Tutorial(time: 10) {
    @Section(title: "Start Receiving Speed Measurements") {
        Begin streaming:
        
        @CodeListing(language: "swift") {
            let stream = try await SmartCoach.startMeasuring()
            
            for await measurement in stream {
            print("Speed:", measurement.measurement.value)
            }
            }
            
            @Step {
                Display speeds in your UI as they arrive.
                }
                }
                
                @Section(title: "Stop Measuring") {
                    End the measurement session:
                    
                    @CodeListing(language: "swift") {
                        try await SmartCoach.stopMeasuring()
                        }
                        
                        @Step {
                            End measuring when the user leaves the screen or disconnects.
                            }
                            }
                            }
