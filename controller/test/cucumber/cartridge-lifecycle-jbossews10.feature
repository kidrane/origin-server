@runtime_extended
@runtime_extended2
@runtime_extended_other2
@rhel-only
@jboss
Feature: Cartridge Lifecycle JBossEWS1.0 Verification Tests
  Scenario: Application Creation
    Given the libra client tools
    And an accepted node
    When 1 jbossews-1.0 applications are created
    Then the applications should be accessible

  Scenario: Application Modification
    Given an existing jbossews-1.0 application
    When the application is changed
    Then it should be updated successfully
    And the application should be accessible

  Scenario: Application Restarting
    Given an existing jbossews-1.0 application
    When the application is restarted
    Then the application should be accessible

  Scenario: Application Tidy
    Given an existing jbossews-1.0 application
    When I tidy the application
    Then the application should be accessible

  Scenario: Application Snapshot
    Given an existing jbossews-1.0 application
    When I snapshot the application
    Then the application should be accessible
    When I restore the application
    Then the application should be accessible

  Scenario: Application Destroying
    Given an existing jbossews-1.0 application
    When the application is destroyed
    Then the application should not be accessible
