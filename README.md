## Deslope ~ Native Flows Swift Sample App

iOS Sample app using Descope for authentication. This app includes

- Swift App client

## Getting Started

This sample app allows you to get familiar with Native Flows using Descope Swift SDK. For an example with all authentication methods, refer to the [Swift Sample App](https://github.com/descope-sample-apps/swift-sample-app).

### Run the app

1. Clone this repo
2. Open the project within Xcode
3. Within the project settings of the project, change the `myProjectId` (If in a non-US region, or using a custom domain with CNAME, replace `myBaseURL` with your specific localized base URL)

![Alt text](Images/setProjectId.png?raw=true "Set Project ID")

4. Run the simulator within Xcode - The play button located in the top left

#### Running Flows

If you're running a hosted flow with this SDK, you can modify the value for the flow Url in the Flow Controller files to include your own hosted page with our Descope Web Component, as well as alter the `?flow=sign-up-or-in` parameter to run a different flow.

```
let url = URL(string: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")
```

### Notes:

1. Enchanted link currently does not route back to the application. You will need to validate the token externally from a web or backend client.

- https://docs.descope.com/build/guides/client_sdks/enchanted-link/#user-verification
- https://docs.descope.com/build/guides/backend_sdks/enchanted-link/#user-verification
