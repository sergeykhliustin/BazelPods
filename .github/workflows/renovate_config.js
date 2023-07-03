module.exports = {
  logLevel: 'debug',
  branchPrefix: 'renovate/',
  gitAuthor: 'Renovate Bot <bot@renovateapp.com>',
  extends: ["config:base"],
  platform: 'github',
  forkProcessing: "disabled",
  repositories: [
    'sergeykhliustin/BazelPods'
  ]
};