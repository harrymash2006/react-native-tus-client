const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const withTusClientAppDelegate = (config) => {
  return withDangerousMod(config, [
    'ios',
    async (config) => {
      const filePath = path.join(config.modRequest.platformProjectRoot, 'AppDelegate.mm');
      
      // Wait for the file to be created
      let retries = 0;
      const maxRetries = 10;
      
      while (!fs.existsSync(filePath) && retries < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
        retries++;
      }
      
      if (!fs.existsSync(filePath)) {
        console.warn('AppDelegate.mm not found after waiting. Skipping TUS client modifications.');
        return config;
      }

      const contents = fs.readFileSync(filePath, 'utf-8');

      // Check if the code is already added
      if (contents.includes('handleEventsForBackgroundURLSession')) {
        return config;
      }

      // Add the import
      const importStatement = '#import "RNTusClient.h"';
      const newContents = contents.replace(
        /#import "AppDelegate.h"/,
        `#import "AppDelegate.h"\n${importStatement}`
      );

      // Add the method
      const methodToAdd = `
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    RNTusClient *tusClient = [self.bridge moduleForClass:[RNTusClient class]];
    [tusClient registerBackgroundHandler:completionHandler];
}`;

      // Find the last @end and add our method before it
      const finalContents = newContents.replace(
        /@end/,
        `${methodToAdd}\n\n@end`
      );

      fs.writeFileSync(filePath, finalContents);
      return config;
    },
  ]);
};

module.exports = (config) => {
  return withTusClientAppDelegate(config);
}; 