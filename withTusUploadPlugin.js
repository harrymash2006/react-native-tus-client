const { withInfoPlist } = require('@expo/config-plugins');

module.exports = function withTusUploadPlugin(config) {
  return withInfoPlist(config, (config) => {
    config.modResults.UIBackgroundModes = config.modResults.UIBackgroundModes || [];
    if (!config.modResults.UIBackgroundModes.includes('processing')) {
      config.modResults.UIBackgroundModes.push('processing');
    }

    config.modResults.BGTaskSchedulerPermittedIdentifiers =
      config.modResults.BGTaskSchedulerPermittedIdentifiers || [];

    const identifiers = ['com.yourcompany.uploadtask']; // Replace with your identifier
    identifiers.forEach((id) => {
      if (!config.modResults.BGTaskSchedulerPermittedIdentifiers.includes(id)) {
        config.modResults.BGTaskSchedulerPermittedIdentifiers.push(id);
      }
    });

    return config;
  });
};
