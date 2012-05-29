#
# Cookbook Name:: haproxy
# Provider:: default
#
# Copyright 2012, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :create do
  package "haproxy" do
    action :install
  end

  template "/etc/default/haproxy" do
    source "haproxy-default.erb"
    cookbook "haproxy"
    owner "root"
    group "root"
    mode "0644"
  end

  directory "/etc/haproxy" do
    owner "root"
    group "root"
    mode "0755"
  end

  directory "/etc/haproxy/config.d" do
    owner "root"
    group "root"
    mode "0755"
  end

  file "/etc/haproxy/haproxy.cfg" do
    action :nothing
    owner "root"
    group "root"
    mode "0644"
  end

  [true, false].each do |initial|
    bash "haproxy config#{initial ? " initial" : ""}" do
      action :nothing unless initial
      user "root"
      cwd "/etc/haproxy"
      code <<-EOH
        find /etc/haproxy/config.d -name "*.cfg" | xargs cat > /etc/haproxy/haproxy.cfg
      EOH
      notifies :create, "file[/etc/haproxy/haproxy.cfg]", :immediately
      notifies :restart, "service[haproxy]" unless initial
    end
  end

  haproxy_configuration "global" do
    source "haproxy.cfg.erb"
    cookbook "haproxy"
  end

  service "haproxy" do
    supports :restart => true, :status => true, :reload => true
    action [:enable, :start]
  end
end
