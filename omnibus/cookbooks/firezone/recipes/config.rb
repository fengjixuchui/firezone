# frozen_string_literal: true

require 'securerandom'

# Cookbook:: firezone
# Recipe:: config
#
# Copyright:: 2014 Chef Software, Inc.
# Copyright:: 2021 Firezone, Inc.
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

# Get and/or create config and secrets.
#
# This creates the config_directory if it does not exist as well as the files
# in it.

Firezone::Config.load_or_create!(
  "#{node['firezone']['config_directory']}/firezone.rb",
  node
)
Firezone::Config.load_or_create_telemetry_id("#{node['firezone']['var_directory']}/cache/telemetry_id", node)
Firezone::Config.load_from_json!(
  "#{node['firezone']['config_directory']}/firezone.json",
  node
)
Firezone::Config.load_or_create_secrets!(
  "#{node['firezone']['config_directory']}/secrets.json",
  node
)

Firezone::Config.audit_config(node['firezone'])
Firezone::Config.maybe_turn_on_fips(node)

# Set SSL email address to admin's email if none was provided.
node.default['firezone']['ssl']['email_address'] ||= node['firezone']['admin_email']

# Copy things we need from the firezone namespace to the top level. This is
# necessary for some community cookbooks.
node.consume_attributes('runit' => node['firezone']['runit'])

user node['firezone']['user']

group node['firezone']['group'] do
  members [node['firezone']['user']]
end

directory node['firezone']['config_directory'] do
  owner node['firezone']['user']
  group node['firezone']['group']
end

directory node['firezone']['var_directory'] do
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0700'
  recursive true
end

directory "#{node['firezone']['app_directory']}/tmp" do
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0700'
  recursive true
end

directory node['firezone']['log_directory'] do
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0700'
  recursive true
end

directory "#{node['firezone']['var_directory']}/etc" do
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0700'
end

file 'configuration-variables' do
  path "#{node['firezone']['config_directory']}/firezone.rb"
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0600'
end

file "#{node['firezone']['config_directory']}/secrets.json" do
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0600'
end

file "#{node['firezone']['var_directory']}/cache/wg_private_key" do
  owner node['firezone']['user']
  group node['firezone']['group']
  mode '0600'
end
