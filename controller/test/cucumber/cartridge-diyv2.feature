@runtime_other
Feature: V2 SDK DIY Cartridge

  Scenario: Add cartridge
  Given a v2 default node
  Given a new diy-0.1 type application
  Then the application git repo will exist
  And the platform-created default environment variables will exist
  And the diy-0.1 cartridge private endpoints will be exposed
  And the diy-0.1 DIY_VERSION env entry will exist
  When I destroy the application
  Then the application git repo will not exist
