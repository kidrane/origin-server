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
# Test the OpenShift application_container model
#
module OpenShift
  ;
end

require 'test_helper'
require 'openshift-origin-node/model/application_container'
require 'openshift-origin-node/model/v2_cart_model'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common'
require 'test/unit'
require 'fileutils'
require 'yaml'
require 'mocha'

class ApplicationContainerTest < Test::Unit::TestCase

  def setup
    # Set up the config
    @config = mock('OpenShift::Config')

    @ports_begin    = 35531
    @ports_per_user = 5
    @uid_begin      = 500

    @config.stubs(:get).with("PORT_BEGIN").returns(@ports_begin.to_s)
    @config.stubs(:get).with("PORTS_PER_USER").returns(@ports_per_user.to_s)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid_begin.to_s)
    @config.stubs(:get).with("GEAR_BASE_DIR").returns("/tmp")

    script_dir     = File.expand_path(File.dirname(__FILE__))
    cart_base_path = File.join(script_dir, '..', '..', '..', 'cartridges')

    raise "Couldn't find cart base path at #{cart_base_path}" unless File.exists?(cart_base_path)

    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns(cart_base_path)

    OpenShift::Config.stubs(:new).returns(@config)

    # Set up the container
    @gear_uuid = "501"
    @user_uid  = "501"
    @app_name  = 'UnixUserTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = "127.0.0.1"

    OpenShift::ApplicationContainer.stubs(:get_build_model).returns(:v2)

    @container = OpenShift::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid,
        @app_name, @gear_uuid, @namespace, nil, nil, nil)

    @mock_manifest = %q{#
        Name: mock
        Cartridge-Short-Name: MOCK
        Cartridge-Version: 1.0
        Cartridge-Vendor: Unit Test
        Display-Name: Mock
        Description: "A mock cartridge for development use only."
        Version: 0.1
        License: "None"
        Vendor: Red Hat
        Categories:
        - service
        Provides:
        - mock
        Scaling:
        Min: 1
        Max: -1
        Group-Overrides:
        - components:
        - mock
        Endpoints:
          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT1
            Private-Port:      8080
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT1
            Mappings:
              - Frontend:      "/front1a"
                Backend:       "/back1a"
                Options:       { websocket: true, tohttps: true }
              - Frontend:      "/front1b"
                Backend:       "/back1b"
                Options:       { noproxy: true }
          
          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT2
            Private-Port:      8081
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT2
            Mappings:
              - Frontend:      "/front2"
                Backend:       "/back2"
                Options:       { file: true }
          
          - Private-IP-Name:   EXAMPLE_IP1
            Private-Port-Name: EXAMPLE_PORT3
            Private-Port:      8082
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT3
            Mappings:
              - Frontend:      "/front3"
                Backend:       "/back3"
          
          - Private-IP-Name:   EXAMPLE_IP2
            Private-Port-Name: EXAMPLE_PORT4
            Private-Port:      9090
            Public-Port-Name:  EXAMPLE_PUBLIC_PORT4
            Mappings:
              - Frontend:      "/front4"
                Backend:       "/back4"
  
          - Private-IP-Name:   EXAMPLE_IP2
            Private-Port-Name: EXAMPLE_PORT5
            Private-Port:      9091
    }

    manifest = "/tmp/manifest-#{Process.pid}"
    IO.write(manifest, @mock_manifest, 0)
    @mock_cartridge = OpenShift::Runtime::Cartridge.new(manifest)
    @container.cartridge_model.stubs(:get_cartridge).with("mock").returns(@mock_cartridge)
  end

  def test_public_endpoints_create
    OpenShift::Utils::Environ.stubs(:for_gear).returns({
        "OPENSHIFT_MOCK_EXAMPLE_IP1" => "127.0.0.1",
        "OPENSHIFT_MOCK_EXAMPLE_IP2" => "127.0.0.2"
    })

    proxy = mock('OpenShift::FrontendProxyServer')
    OpenShift::FrontendProxyServer.stubs(:new).returns(proxy)

    proxy.expects(:add).with(@user_uid, "127.0.0.1", 8080).returns(@ports_begin)
    proxy.expects(:add).with(@user_uid, "127.0.0.1", 8081).returns(@ports_begin+1)
    proxy.expects(:add).with(@user_uid, "127.0.0.1", 8082).returns(@ports_begin+2)
    proxy.expects(:add).with(@user_uid, "127.0.0.2", 9090).returns(@ports_begin+3)

    @container.user.expects(:add_env_var).returns(nil).times(4)
    
    @container.create_public_endpoints(@mock_cartridge.name)
  end

  def test_public_endpoints_delete
    OpenShift::Utils::Environ.stubs(:for_gear).returns({
        "OPENSHIFT_MOCK_EXAMPLE_IP1" => "127.0.0.1",
        "OPENSHIFT_MOCK_EXAMPLE_IP2" => "127.0.0.2"
    })

    proxy = mock('OpenShift::FrontendProxyServer')
    OpenShift::FrontendProxyServer.stubs(:new).returns(proxy)

    proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.1", 8080).returns(@ports_begin)
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.1", 8081).returns(@ports_begin+1)
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.1", 8082).returns(@ports_begin+2)
    proxy.expects(:find_mapped_proxy_port).with(@user_uid, "127.0.0.2", 9090).returns(@ports_begin+3)

    delete_all_args = [@ports_begin, @ports_begin+1, @ports_begin+2, @ports_begin+3]
    proxy.expects(:delete_all).with(delete_all_args, true).returns(nil)

    @container.user.expects(:remove_env_var).returns(nil).times(4)

    @container.delete_public_endpoints(@mock_cartridge.name)
  end

  def test_tidy_success
    OpenShift::Utils::Environ.stubs(:for_gear).returns(
        {'OPENSHIFT_HOMEDIR' => '/foo', 'OPENSHIFT_APP_NAME' => 'app_name' })

    @container.stubs(:stop_gear).with('/foo')
    @container.stubs(:gear_level_tidy).with('/foo/git/app_name.git', '/foo/.tmp')
    @container.cartridge_model.expects(:tidy)
    @container.stubs(:start_gear)

    @container.stubs(:cartridge_model).returns(mock())

    @container.tidy
  end

  def test_tidy_stop_gear_fails
    OpenShift::Utils::Environ.stubs(:for_gear).returns(
        {'OPENSHIFT_HOMEDIR' => '/foo', 'OPENSHIFT_APP_NAME' => 'app_name' })

    @container.stubs(:stop_gear).with('/foo').raises(Exception.new)
    @container.stubs(:gear_level_tidy).with('/foo/git/app_name.git', '/foo/.tmp').never
    @container.cartridge_model.expects(:tidy).never
    @container.stubs(:start_gear).never

    assert_raise Exception do
      @container.tidy
    end
  end

  def test_tidy_gear_level_tidy_fails
    OpenShift::Utils::Environ.stubs(:for_gear).returns(
        {'OPENSHIFT_HOMEDIR' => '/foo', 'OPENSHIFT_APP_NAME' => 'app_name'})

    @container.expects(:stop_gear).with('/foo')
    @container.expects(:gear_level_tidy).with('/foo/git/app_name.git', '/foo/.tmp').raises(Exception.new)
    @container.expects(:start_gear)

    @container.tidy
  end

  def test_force_stop
    FileUtils.mkpath("/tmp/#@user_uid/app-root/runtime")
    OpenShift::UnixUser.stubs(:kill_procs).with(@user_uid).returns(nil)
    @container.force_stop
  end
end
