# Testing

This package uses `package:integration_test` to run its tests in a web browser.

See [Plugin Tests > Web Tests](https://github.com/flutter/flutter/wiki/Plugin-Tests#web-tests) in the Flutter wiki for instructions to setup and run the tests in this package.

Check [flutter.dev > Integration testing](https://flutter.dev/docs/testing/integration-tests) for more info.

Using [web driver for integration tests](https://flutter.dev/docs/cookbook/testing/integration/introduction#6b-web). There is a `run_test` script that ensures that chromedriver is running and executes test targets in Chrome with the integration driver. Tests that do not require the use of web API may be put in tests directory as usual.

Debugging integration tests might not work in VS Code. In that case you can try running the specific test with: `flutter run -d web-server --target integration_test/share_handler_web_test.dart --debug`, then opening the provided link in the browser and debugging the dart code in Chrome inspection tools.

Some web API may require the web page to be run in HTTPS. In that case you may build the web app with `flutter build web` (this might require `index.html` to be created), go to `build/web` and start the app with http-server (for instance `http-server . -p 2001 -S -C cert.pem -o`).