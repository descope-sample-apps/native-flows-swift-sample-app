<img width="1049" alt="image" src="https://github.com/user-attachments/assets/4f8e5575-d7c6-4bdb-8f64-66b9be0c0874">

# Descope's Native Flows Swift Sample App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Welcome to Descope's Native Flows Swift Sample App, a demonstration of how to integrate Descope native flows for user authentication within a Swift application. By exploring this project, you can understand how Descope works with Swift to manage native flows. For an example with all authentication methods, refer to the [Swift Sample App](https://github.com/descope-sample-apps/swift-sample-app).

## Features
This sample app includes:

- **App Client**: An example of how the client communicates with Descope.
- **CIBA Push Approval**: An example of approving a CIBA request, such as one from an AI agent, that Descope pushes to the user's device.

## Getting Started
Follow these steps to run the sample app and explore Descope's capabilities with Swift:

### Prerequisites
Make sure you have the following installed:

- XCode
- an IOS Simulator

### Run the app

1. Clone this repo
2. Open the project within Xcode
3. Within the project settings of the project, change the `myProjectId` (If in a non-US region, or using a custom domain with CNAME, replace `myBaseURL` with your specific localized base URL)

![Alt text](.github/images/setProjectId.png?raw=true "Set Project ID")

4. **(Optional) Self-Host Your Flow**: Your Descope authentication flow is automatically hosted by Descope at `https://auth.descope.io/<your_descope_project_id>` but you can use your own website or domain to host your flow. You can modify the value for the flow URL in the Flow Controller files to include your own hosted page with our Descope Web Component, as well as alter the `?flow=sign-up-or-in` parameter to run a different flow.

```swift
let flow = DescopeFlow(url: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")
```

> For more information about Auth Hosting, visit our docs on it [here](https://docs.descope.com/auth-hosting-app)

5. Run the simulator within Xcode - The play button located in the top left

7. Change the value of the `appInterface` value in `AppInterface.swift` to see other examples of authentication screens

### Notes:

1. Enchanted link currently does not route back to the application. You will need to validate the token externally from a web or backend client.

- https://docs.descope.com/build/guides/client_sdks/enchanted-link/#user-verification
- https://docs.descope.com/build/guides/backend_sdks/enchanted-link/#user-verification

## CIBA Push Approval

The app can also approve [CIBA](https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html) requests, for example an AI agent asking the user to approve a booking or a payment. Descope sends the request to the user's phone as a push notification. The user taps it, reviews the request, confirms with Face ID or the passcode, and approves it in the CIBA flow, which runs with the session the user is already signed in with.

The approval screen is in `src/views/ciba/CIBAController.swift`, and push enrollment and notification handling are in `src/app/AppDelegate.swift`.

### Prerequisites

- An Apple developer account with an APNs key (`.p8` file)
- An iPhone, or the iOS Simulator on a Mac with Apple silicon
- A Descope project with a CIBA flow (`ciba-authentication`)

### Set up your Descope project

1. Under **Connectors**, add an **APN** connector with your APNs key (the contents of the `.p8` file), its Key ID, your Team ID and the app's bundle ID. One key works for both the sandbox (debug builds and the simulator) and production (TestFlight and the App Store)
2. Under **Inbound Apps**, create an app for the agent. In its CIBA settings set the delivery method to **Push notification** and pick the APN connector. Its login page URL must be on the same host as `myBaseURL`, for example `https://api.descope.com/login/<your_descope_project_id>?flow=ciba-authentication`, otherwise the app ignores the push

### Run the demo

1. Follow the steps in [Run the app](#run-the-app) to set `myProjectId` and `myBaseURL`
2. In the target's **Signing & Capabilities**, pick your team and a bundle ID that matches the APN connector
3. Run the app on your iPhone or on the simulator, sign in with your email, and allow notifications when asked
4. Play the agent from a terminal with the inbound app's credentials and the email you signed in with:

```bash
CLIENT_ID=<inbound_app_client_id> CLIENT_SECRET=<inbound_app_secret> LOGIN_HINT=<your_email> ./ciba-demo.sh
```

To ask for a payment approval with [RFC 9396](https://www.rfc-editor.org/rfc/rfc9396) `authorization_details` instead:

```bash
RAR=1 CLIENT_ID=<inbound_app_client_id> CLIENT_SECRET=<inbound_app_secret> LOGIN_HINT=<your_email> ./ciba-demo.sh 142.50 EUR "Acme Store"
```

5. Tap the notification, review the request and approve it. The script prints the claims of the token the agent received

### Notes:

1. The app uses DescopeKit from the `feat/ciba-push-request` branch until the CIBA push API is released.
2. "Not now" leaves the request to expire, since the SDK has no deny call yet.
3. The CIBA flow ends on a result screen, so the flow screen has a Close button.
4. The sign in screen is `simpleFlow` by default, since the agent finds the user by email. Any other screen works as long as the user signs in with their email.

## Learn More
To learn more please see the [Descope Documentation and API reference page](https://docs.descope.com/).

## Contact Us
If you need help you can [contact us](https://docs.descope.com/support/)

## License
Descope's Native Flows Swift Sample App is licensed for use under the terms and conditions of the MIT license Agreement.
