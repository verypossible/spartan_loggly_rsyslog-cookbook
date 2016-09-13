#
# Cookbook Name:: spartan_base
# Spec:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'spartan_loggly_rsyslog::default' do
  let(:token) { SecureRandom.base64 }
  let(:file_cache_path) { '/tmp/var/chef/cache' }

  context 'when the loggly token is *not* set' do
    let(:chef_run) { ChefSpec::ServerRunner.new(file_cache_path: file_cache_path).converge(described_recipe) }

    it 'raises an error' do
      expect { chef_run }.to raise_error(StandardError)
    end
  end

  let(:loggly_conf) { '/etc/rsyslog.d/22-loggly.conf' }
  let(:files_conf) { '/etc/rsyslog.d/99-files.conf' }
  let(:crt_path) { '/etc/rsyslog.d/keys/ca.d' }
  let(:crt_file) { 'logs-01.loggly.com_sha12.crt' }
  let(:crt_file_path) { "#{crt_path}/#{crt_file}" }
  let(:crt_remote_resource) { 'download loggly.com cert' }
  let(:rsyslog_group) { 'syslog' }

  let(:chef_run) do
    ChefSpec::ServerRunner.new(file_cache_path: file_cache_path) do |node|
      node.set.loggly.token = token
      node.normal.rsyslog.priv_group = rsyslog_group
    end.converge(described_recipe)
  end

  it 'uses 64k as the max_message_size' do
    expect(chef_run.node.rsyslog.max_message_size).to eq '64k'
    expect(chef_run).to render_file('/etc/rsyslog.conf').with_content(/^\$MaxMessageSize 64k$/)
  end

  let(:port) { 6514 }
  it 'uses 6514 as the port' do
    expect(chef_run.node.loggly.rsyslog.port).to eq port
  end

  let(:host) { 'logs-01.loggly.com' }
  it 'uses logs-01.loggly.com as the host' do
    expect(chef_run.node.loggly.rsyslog.host).to eq host
  end

  it 'installs the rsyslog-gnutls package' do
    expect(chef_run).to install_package('rsyslog-gnutls')
  end

  it 'creates a directory for the certificate' do
    expect(chef_run).to create_directory(crt_path).with(
      owner: 'root',
      group: rsyslog_group,
      mode: 0750
    )
  end

  it 'download the loggly certificate' do
    expect(chef_run).to create_remote_file(crt_remote_resource).with(
      path: "#{crt_path}/#{crt_file}"
    )
  end

  it 'crt download notifies the rsyslog service to restart' do
    expect(
      chef_run.find_resource(:remote_file, crt_remote_resource)
    ).to notify('service[rsyslog]').to(:restart)
  end

  it 'contains the correct TLS configuration settings' do
    [
      "$DefaultNetstreamDriverCAFile #{crt_file_path}",
      '$ActionSendStreamDriver gtls',
      '$ActionSendStreamDriverMode 1',
      '$ActionSendStreamDriverAuthMode x509/name',
      '$ActionSendStreamDriverPermittedPeer *.loggly.com'
    ].each do |line|
      expect(chef_run).to render_file(loggly_conf).with_content(/^#{Regexp.escape(line)}$/)
    end
  end

  it 'main loggly config notifies the rsyslog service to restart' do
    expect(
      chef_run.find_resource(:template, loggly_conf)
    ).to notify('service[rsyslog]').to(:restart)
  end

  it 'creates loggly rsyslog template with no tags' do
    expect(chef_run).to create_template(loggly_conf).with(
      owner: 'root',
      group: 'root',
      variables: {
        crt_file: crt_file_path,
        tags: '',
        token: token
      }
    )

    [
      "[#{token}@41058 ]",
      "target=\"#{host}\" port=\"#{port}\""
    ].each do |content|
      expect(chef_run).to render_file(loggly_conf).with_content(/#{Regexp.escape(content)}/)
    end
  end

  context 'with tags' do
    let(:tags) { %w(Test fOO bar) }
    let(:generated_tags) { tags.map { |tag| "tag=\\\"#{tag}\\\"" }.join(' ') }
    let(:chef_run) do
      ChefSpec::ServerRunner.new(file_cache_path: file_cache_path) do |node|
        node.set.loggly.token = token
        node.set.loggly.tags = tags
      end.converge(described_recipe)
    end

    it 'creates loggly rsyslog config' do
      expect(chef_run).to create_template(loggly_conf).with(
        owner: 'root',
        group: 'root',
        variables: {
          crt_file: crt_file_path,
          tags: generated_tags,
          token: token
        }
      )

      [
        "[#{token}@41058 #{generated_tags}]",
        "target=\"#{host}\" port=\"#{port}\""
      ].each do |content|
        expect(chef_run).to render_file(loggly_conf).with_content(/#{Regexp.escape(content)}/)
      end
    end
  end

  context 'with bad file values' do
    let(:files) do
      [
        { tag: 'missing filename' },
        { tag: 'empty filename', filename: '' },
        { 'tag' => 'string keys', 'filename' => ' ' },
        { tag: 'whitespace filename', filename: " \n\t\n " }
      ]
    end
    let(:chef_run) do
      ChefSpec::ServerRunner.new(file_cache_path: file_cache_path) do |node|
        node.set.loggly.token = token
        node.set.loggly.log_files = files
      end.converge(described_recipe)
    end

    it 'should *not* create a file config' do
      expect(chef_run).not_to create_template(files_conf)
    end
  end

  context 'with good file values' do
    let(:files) do
      [
        { 'filename' => '/string/key.file.ext' },
        { filename: '/just/a/file.log' },
        { filename: '/every/thing.txt', tag: 'all the options', statefile: '/tmp/state', severity: 'Warning' }
      ]
    end
    let(:chef_run) do
      ChefSpec::ServerRunner.new(file_cache_path: file_cache_path) do |node|
        node.set.loggly.token = token
        node.set.loggly.log_files = files
      end.converge(described_recipe)
    end

    it 'should create a file config' do
      expect(chef_run).to create_template(files_conf).with(owner: 'root', group: 'root')

      expected_files_conf = <<-EOS.gsub(/^ {8}/, '')
        # This file was generated by Chef

        module(load="imfile" PollingInterval="#{chef_run.node.loggly.rsyslog.input_file_poll_interval}")

        input(type="imfile"
              File="/string/key.file.ext"
              Tag="key-file-ext"
              Statefile="/string/key.file.ext.rsyslog_state"
          )
        input(type="imfile"
              File="/just/a/file.log"
              Tag="file-log"
              Statefile="/just/a/file.log.rsyslog_state"
          )
        input(type="imfile"
              File="/every/thing.txt"
              Tag="all the options"
              Statefile="/tmp/state"
              Severity="Warning"
          )
      EOS

      expect(chef_run).to render_file(files_conf).with_content(expected_files_conf)
    end
  end

  context 'on a ubuntu platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(file_cache_path: file_cache_path,
                                 platform: 'ubuntu',
                                 version: '14.04') do |node|
        node.set.loggly.token = token
      end.converge(described_recipe)
    end

    it 'does not run a ruby block to check the rsyslog package version' do
      expect(chef_run).not_to run_ruby_block('installed_rsyslog_version_check')
    end
  end

  context 'on a redhat platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(file_cache_path: file_cache_path,
                                 platform: 'centos',
                                 version: '6.7') do |node|
        node.set.loggly.token = token
      end.converge(described_recipe)
    end

    it 'runs a ruby block to check the rsyslog package version' do
      expect(chef_run).to run_ruby_block('installed_rsyslog_version_check')
    end
  end
end
