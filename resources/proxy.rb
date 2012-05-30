#
# Cookbook Name:: haproxy
# Resource:: proxy
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

default_action :create
actions :delete

def self.attribute(attr_name, opts={})
  if section_names = opts.delete(:section)
  #   section_names = (section_names.is_a?(Array) ? section_names : [section_names]).map{|name| name.to_sym}
  #   opts[:callbacks] ||= {}
  #   opts[:callbacks]["can only be used in #{section_names.join(", ")} sections"] = lambda do
  #     section_names.include?(self.proxy_type.to_sym)
  #   end
  end
  if opts[:kind_of] && opts[:kind_of] < Chef::Resource
    resource_class = opts.delete(:kind_of)
  end
  append = opts.delete(:append)
  opts[:default] ||= [] if append
  super(attr_name, opts)
  if resource_class
    orig_method = instance_method(attr_name)
    define_method(attr_name) do |*args, &block|
      arg = args[0] && begin
        resource = resource_class.new(args[0], run_context)
        resource.enclosing_provider = enclosing_provider
        resource.instance_eval(&block) if block
        resource
      end
      if append && arg
        orig_method.bind(self).call << arg
      else
       orig_method.bind(self).call(arg)
      end
    end
  end
end

attribute :proxy_type, :equal_to => [:default, :frontend, :listen, :backend], :default => :listen

class AppSession < Chef::Resource
  attribute :cookie, :kind_of => String, :name_attribute => true
  attribute :length, :kind_of => Integer, :required => true
  attribute :timeout, :kind_of => Integer, :required => true
  attribute :request_learn, :equal_to => [true, false], :default => true
  attribute :prefix, :equal_to => [true, false], :default => false
  attribute :mode, :equal_to => [:path_parameters, "path-parameters ", :query_string, "query-string"]
end

attribute :appsession, :kind_of => AppSession, :section => [:listen, :backend]

class Bind < Chef::Resource
  attribute :address, :kind_of => String, :name_attribute => true
  # Apply only to non-path addresses
  attribute :interface, :kind_of => String
  attribute :mss, :kind_of => Integer
  attribute :transparent, :equal_to => [true, false], :default => false
  attribute :bind_id, :kind_of => Integer
  attribute :bind_name, :kind_of => String
  attribute :defer_accept, :equal_to => [true, false], :default => false
  attribute :accept_proxy, :equal_to => [true, false], :default => false
  # Apply only to path addresses
  attribute :mode, :kind_of => [String, Integer]
  attribute :user, :kind_of => String
  attribute :uid, :kind_of => Integer
  attribute :group, :kind_of => String
  attribute :gid, :kind_of => Integer

  def to_cfg
    cfg = ["bind #{address}"]
    if address[0] == '/'
      # Path-like
      cfg << "mode #{mode.is_a?(Integer) ? "0" + mode.to_s(8) : mode}" if mode
      # Don't allow both user and uid together (and ditto for group/gid)
      if user
        cfg << "user #{user}"
      elsif uid
        cfg << "uid #{uid}"
      end
      if group
        cfg << "group #{group}"
      elsif
        cfg << "gid #{gid}"
      end
    else
      # Network-like
      cfg << "interface #{interface}" if interface
      cfg << "mss #{mss}" if mss
      cfg << "transparent" if transparent
      cfg << "id #{bind_id}" if bind_id
      cfg << "name #{bind_name}" if bind_name
      cfg << "defer-accept" if defer_accept
      cfg << "accept-proxy" if accept_proxy
    end
    cfg.join(' ')
  end
end

attribute :bind, :kind_of => Bind, :section => [:frontend, :listen], :append => true

