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
      orig_method.bind(self).call(arg)
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
