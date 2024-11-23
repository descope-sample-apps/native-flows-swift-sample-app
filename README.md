# Descope's Native Flows Swift Sample App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Welcome to Descope's Native Flows Swift Sample App, a demonstration of how to integrate Descope native flows for user authentication within a Swift application. By exploring this project, you can understand how Descope works with Swift to manage native flows. For an example with all authentication methods, refer to the [Swift Sample App](https://github.com/descope-sample-apps/swift-sample-app).

## Features
This sample app includes:

- **App Client**: An example of how the client communicates with Descope.

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

![Alt text](Images/setProjectId.png?raw=true "Set Project ID")

4. **(Optional) Self-Host Your Flow**: Your Descope authentication flow is automatically hosted by Descope at [https://auth.descope.io/<your_descope_project_id>](https://auth.descope.com/<your_descope_project_id>) but you can use your own domain as host. You can modify the value for the flow Url in the Flow Controller files to include your own hosted page with our Descope Web Component, as well as alter the `?flow=sign-up-or-in` parameter to run a different flow.

```
let url = URL(string: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")
```

5. Run the simulator within Xcode - The play button located in the top left

### Notes:

1. Enchanted link currently does not route back to the application. You will need to validate the token externally from a web or backend client.

- https://docs.descope.com/build/guides/client_sdks/enchanted-link/#user-verification
- https://docs.descope.com/build/guides/backend_sdks/enchanted-link/#user-verification

## Learn More
To learn more please see the [Descope Documentation and API reference page](https://docs.descope.com/).

## Contact Us
If you need help you can [contact us](https://docs.descope.com/support/)

## License
Descope's Native Flows Swift Sample App is licensed for use under the terms and conditions of the MIT license Agreement.