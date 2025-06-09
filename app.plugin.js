const { withXcodeProject } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const withTusClientAppDelegate = (config) => {
  return withXcodeProject(config, async (config) => {
    const xcodeProject = config.modResults;
    const platformProjectRoot = config.modRequest.platformProjectRoot;

    // Create a post-build script to modify AppDelegate
    const postBuildScript = `
      #!/bin/bash
      APP_DELEGATE_PATH="$SRCROOT/AppDelegate.mm"
      
      if [ -f "$APP_DELEGATE_PATH" ]; then
        # Check if the code is already added
        if ! grep -q "handleEventsForBackgroundURLSession" "$APP_DELEGATE_PATH"; then
          # Add the import
          sed -i '' 's/#import "AppDelegate.h"/#import "AppDelegate.h"\\n#import "RNTusClient.h"/' "$APP_DELEGATE_PATH"
          
          # Add the method
          METHOD='\\
    - (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {\\
        RNTusClient *tusClient = [self.bridge moduleForClass:[RNTusClient class]];\\
        [tusClient registerBackgroundHandler:completionHandler];\\
    }'
          
          # Add the method before the last @end
          sed -i '' "s/@end/$METHOD\\n\\n@end/" "$APP_DELEGATE_PATH"
        fi
      fi
    `;

    // Write the post-build script to a file
    const scriptPath = path.join(platformProjectRoot, 'tus-post-build.sh');
    fs.writeFileSync(scriptPath, postBuildScript);
    fs.chmodSync(scriptPath, '755'); // Make it executable

    // Add the script to the Xcode project's build phases
    const buildPhases = xcodeProject.pbxProjectSection();
    const buildPhase = buildPhases.find(phase => phase.name === 'Run Script');
    if (buildPhase) {
      buildPhase.shellScript = `"${scriptPath}"`;
    }

    return config;
  });
};

module.exports = (config) => {
  return withTusClientAppDelegate(config);
}; 