@Tutorial(time: 8) {
    @Section(title: "Common Configuration Errors") {
        - missing API key  
        - invalid bundle identifier  
        - configure() called twice  
        
        @Step {
            Check the error message returned by SmartCoachError.configuratiaonError.
            }
            }
            
            @Section(title: "Connection Errors") {
                Examples:
                
                - RadarError.invalidSessionState  
                - BluetoothError.connectionFailed  
                - notificationFailure  
                
                @Step {
                    Handle connection failures by showing an alert or retry option.
                    }
                    }
                    
                    @Section(title: "Measurement Stream Ended") {
                        The stream ends if:
                        - Device disconnects  
                        - Bluetooth error  
                        - stopMeasuring() was called  
                        - Task was cancelled  
                        
                        @Step {
                            Restart scanning or return the user to the device list.
                            }
                            }
                            }
