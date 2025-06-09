// withTusUploadPlugin.js
const { withInfoPlist } = require('@expo/config-plugins');

const TUS_UPLOAD_IDENTIFIER = 'com.tuskit.upload';

/**
 * Plugin to add required Info.plist entries for TUS upload background processing
 */
const withTusUploadPlugin = (config) => {
  return withInfoPlist(config, (config) => {
    // Add UIBackgroundModes
    config.modResults.UIBackgroundModes = config.modResults.UIBackgroundModes || [];
    if (!config.modResults.UIBackgroundModes.includes('processing')) {
      config.modResults.UIBackgroundModes.push('processing');
    }

    // Add BGTaskSchedulerPermittedIdentifiers
    config.modResults.BGTaskSchedulerPermittedIdentifiers =
      config.modResults.BGTaskSchedulerPermittedIdentifiers || [];

    if (!config.modResults.BGTaskSchedulerPermittedIdentifiers.includes(TUS_UPLOAD_IDENTIFIER)) {
      config.modResults.BGTaskSchedulerPermittedIdentifiers.push(TUS_UPLOAD_IDENTIFIER);
    }

    return config;
  });
};

// Export the plugin as a default export
module.exports = withTusUploadPlugin;
