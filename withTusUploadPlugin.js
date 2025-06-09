// withTusUploadPlugin.js
const { withInfoPlist } = require('@expo/config-plugins');

const TUS_UPLOAD_IDENTIFIER = 'io.tus.uploading';

/**
 * Plugin to add required Info.plist entries for TUS upload background processing
 * @param {import('@expo/config-plugins').ConfigPlugin} config
 * @returns {import('@expo/config-plugins').ConfigPlugin}
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

module.exports = withTusUploadPlugin;
