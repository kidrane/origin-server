require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  module Utils
    class Cgroups
      def self.with_cgroups_disabled(uuid)
        begin
          disable_cgroups(uuid)
          yield
        ensure
          enable_cgroups(uuid)
        end
      end

      def self.disable_cgroups(uuid)
        OpenShift::Utils::oo_spawn("oo-admin-ctl-cgroups stopuser #{uuid}",
                                   expected_exitstatus: 0)
      end

      def self.enable_cgroups(uuid)
        OpenShift::Utils::oo_spawn("oo-admin-ctl-cgroups startuser #{uuid}",
                                   expected_exitstatus: 0)
      end
    end
  end
end
