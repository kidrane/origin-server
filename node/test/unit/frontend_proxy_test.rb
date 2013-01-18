#!/usr/bin/env oo-ruby
#--
# Copyright 2013 Red Hat, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
#
# Test the OpenShift frontend_proxy model
#
module OpenShift; end

require 'openshift-origin-node/model/frontend_proxy'
require 'test/unit'
require 'fileutils'
require 'mocha'

# Run unit test manually
# ruby -I node/lib:common/lib node/test/unit/frontend_proxy_test.rb
class TestFrontendProxy < Test::Unit::TestCase

  def setup
    config = mock('OpenShift::Config')

    @ports_begin = 35531
    @ports_per_user = 5
    @uid_begin = 500

    config.stubs(:get).with("PORT_BEGIN").returns(@ports_begin.to_s)
    config.stubs(:get).with("PORTS_PER_USER").returns(@ports_per_user.to_s)
    config.stubs(:get).with("UID_BEGIN").returns(@uid_begin.to_s)

    OpenShift::Config.stubs(:new).returns(config)
  end

  # Simple test to validate the port range computation given
  # a certain UID.
  def test_port_range
    proxy = OpenShift::FrontendProxyServer.new
    
    range = proxy.port_range(500)

    assert_equal range.begin, @ports_begin
    assert_equal range.end, (@ports_begin + @ports_per_user)
  end

  # Verify a valid mapping request is mapped to a port.
  def test_valid_add
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).once
    proxy.expects(:system_proxy_set).returns(['', '', 0]).once

    mapped_port = proxy.add(uid, '127.0.0.1', 8080)
    assert_equal 35531, mapped_port
  end

  # When adding the same mapping twice, the existing port mapping
  # should be returned immediately.
  def test_valid_add_twice
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).once
    proxy.expects(:system_proxy_set).returns(['', '', 0]).once

    mapped_port = proxy.add(uid, '127.0.0.1', 8080)
    assert_equal 35531, mapped_port

    proxy.expects(:system_proxy_show).returns("127.0.0.1:8080").once
    mapped_port = proxy.add(uid, '127.0.0.1', 8080)

    assert_equal 35531, mapped_port
  end

  # Ensures that a non-zero return code from a system proxy set
  # attempt during an add operation raises an exception.
  def test_add_system_error
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).once
    proxy.expects(:system_proxy_set).returns(['Stdout', 'Stderr', 1]).once

    assert_raises OpenShift::FrontendProxyServerException do
      proxy.add(uid, '127.0.0.1', 8080)  
    end
  end

  # Verifies that an exception is thrown if all ports in the given
  # UID's range are already mapped to an address.
  def test_out_of_ports_during_add
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns("127.0.0.1:9000").times(@ports_per_user)
    proxy.expects(:system_proxy_set).never

    assert_raises OpenShift::FrontendProxyServerException do
      proxy.add(uid, '127.0.0.1', 8080)  
    end
  end

  # Verifies that a successful system proxy delete is executed for
  # an existing mapping.
  def test_delete_success
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).with(35531).returns("127.0.0.1:8080").once
    proxy.expects(:system_proxy_delete).with(35531).returns(['', '', 0]).once

    proxy.delete(uid, "127.0.0.1", 8080)
  end

  # Ensures that no system proxy delete is attempted when no mapping
  # to the requested address is found.
  def test_delete_nonexistent
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).returns(nil).at_least_once
    proxy.expects(:system_proxy_delete).never

    proxy.delete(uid, "127.0.0.1", 8080)
  end

  # Verifies an exception is raised when a valid delete attempt to the
  # system proxy returns a non-zero exit code.
  def test_delete_failure
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_show).with(35531).returns("127.0.0.1:8080").once
    proxy.expects(:system_proxy_delete).with(35531).returns(['Stdout', 'Stderr', 1]).once

    assert_raises OpenShift::FrontendProxyServerException do
      proxy.delete(uid, "127.0.0.1", 8080)
    end
  end

  # Tests that a successful delete of all proxy mappings for the UID
  # results in a batch of 5 ports being sent to the system proxy command.
  def test_delete_all_success
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_delete).with(anything, anything, anything, anything, anything).returns(['', '', 0]).once

    proxy.delete_all_for_uid(uid, false)
  end

  # Ensures that a non-zero response from the system proxy delete call
  # and the ignore errors flag disables results in an exception bubbling.
  def test_delete_all_ignore
    proxy = OpenShift::FrontendProxyServer.new

    uid = 500

    proxy.expects(:system_proxy_delete).with(anything, anything, anything, anything, anything).returns(['Stdout', 'Stderr', 1]).once

    assert_raises OpenShift::FrontendProxyServerException do
      proxy.delete_all_for_uid(uid, false)
    end
  end

  # Verify the command line constructed by the system proxy delete
  # given a variety of arguments.
  def test_system_proxy_delete
    proxy = OpenShift::FrontendProxyServer.new

    proxy.expects(:shellCmd).with(equals("openshift-port-proxy-cfg setproxy 1 delete")).once
    proxy.system_proxy_delete(1)

    proxy.expects(:shellCmd).with(equals("openshift-port-proxy-cfg setproxy 1 delete 2 delete 3 delete")).once
    proxy.system_proxy_delete(1, 2, 3)
  end

  # Verify the command line constructed by the system proxy add command
  # given a variety of arguments.
  def test_system_proxy_add
    proxy = OpenShift::FrontendProxyServer.new    

    proxy.expects(:shellCmd).with(equals('openshift-port-proxy-cfg setproxy 3000 "127.0.0.1:1000"')).once
    proxy.system_proxy_set({:proxy_port => 3000, :addr => '127.0.0.1:1000'})

    proxy.expects(:shellCmd)
      .with(equals('openshift-port-proxy-cfg setproxy 3000 "127.0.0.1:1000" 3001 "127.0.0.1:1001" 3002 "127.0.0.1:1002"'))
      .once

    proxy.system_proxy_set(
      {:proxy_port => 3000, :addr => '127.0.0.1:1000'},
      {:proxy_port => 3001, :addr => '127.0.0.1:1001'},
      {:proxy_port => 3002, :addr => '127.0.0.1:1002'}
      )
  end
end