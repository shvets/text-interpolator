require File.expand_path('spec_helper', File.dirname(__FILE__))

require 'text_interpolator'

RSpec.describe TextInterpolator do

  context "#interpolate_string" do
    it "interpolates string with %{} symbol tokens" do
      env = {name1: 'value1', name2: 'value2'}

      expect(subject.interpolate_string "%{name1}, %{name2}", env).to eq "value1, value2"
    end

    it "interpolates string with %{} string tokens" do
      env = {'name1' => 'value1', 'name2' => 'value2'}

      expect(subject.interpolate_string "%{name1}, %{name2}", env).to eq "value1, value2"
    end

    it "interpolates string with '#{}' token" do
      env = {name1: 'value1', name2: 'value2'}

      expect(subject.interpolate_string '#{name1}, #{name2}', env).to eq "value1, value2"
    end

    it "interpolates string with ENV token" do
      ENV['name1'] = 'name1'
      ENV['name2'] = 'name2'

      expect(subject.interpolate_string "ENV['name1'], ENV['name2']").to eq "name1, name2"
    end

    it "interpolates string with ENV token and white space" do
      ENV['name1'] = 'value1'
      ENV['name2'] = 'value2'

      expect(subject.interpolate_string " ENV['name1'], ENV['name2']").to eq " value1, value2"
    end

    it "interpolates string with mixed tokens" do
      env = {name1: 'value1', name2: 'value2'}
      ENV['name3'] = 'value3'

      expect(subject.interpolate_string '#{name1}, #{name2}, ENV[\'name3\']', env).to eq "value1, value2, value3"
    end

    it "interpolates string with multi-level tokens" do
      env = {"name1" => 'value1', 'level2.name2' => 'value2'}

      result = subject.interpolate_string '#{name1}, #{level2.name2}', env

      expect(subject.errors).to be_empty
      expect(result).to eq "value1, value2"
    end

    it "interpolates string with multi-level tokens (part 2)" do
      env = {name1: 'value1', level2: {name2: 'value2'}}

      result = subject.interpolate_string '#{name1}, #{level2.name2}', env

      expect(subject.errors).to be_empty
      expect(result).to eq "value1, value2"
    end
  end

  context "#interpolate_io" do
    it "interpolates io stream"  do
      env = {name1: 'value1', name2: 'value2'}
      ENV['name3'] = 'value3'

      io = StringIO.new '#{name1}, #{name2}, ENV[\'name3\']'

      expect(subject.interpolate_io io, env).to eq "value1, value2, value3"
    end
  end

  context "#interpolate_hash" do
    it "interpolates simple hash" do
      hash = {
        user: ENV['USER'],
        oracle_base: '/usr/local/oracle',
        oracle_version: '11.2.0.4.0',
        src_dir: '#{user}/downloads',
        dest_dir: '#{oracle_base}/instantclient_11_2',
        basic_zip: '#{src_dir}/instantclient-basic-macos.x64-#{oracle_version}.zip'
      }

      result = subject.interpolate_hash hash

      expect(result[:user]).to eq ENV['USER']
      expect(result[:oracle_base]).to eq '/usr/local/oracle'
      expect(result[:dest_dir]).to eq '/usr/local/oracle/instantclient_11_2'
      expect(result[:basic_zip]).to eq ENV['USER'] + '/downloads/instantclient-basic-macos.x64-11.2.0.4.0.zip'
    end

    it "interpolates multi-level hash" do
      hash = {
        host: 'localhost',
        user: ENV['USER'],
        home: ENV['HOME'],

        credentials: {
          user: "some_user",
          password: "some_password",

          settings: {
            user: "some_user2"
          }
        },

        postgres: {
          hostname: '#{host}',
          user: '#{credentials.user}',
          password: 'postgres'
        },

        mysql: {
          user: '#{credentials.settings.user}',
        },

        project: {
          home: '/some_home'
        },

        instant_client: {
          src_dir: '#{project.home}/downloads',
          basic_zip: '#{instant_client.src_dir}/instantclient-basic-macos.x64-123.zip'
        },
      }

      result = subject.interpolate hash

      expect(result[:postgres][:user]).to eq hash[:credentials][:user]
      expect(result[:mysql][:user]).to eq hash[:credentials][:settings][:user]

      expect(result[:instant_client][:basic_zip]).to eq "/some_home/downloads/instantclient-basic-macos.x64-123.zip"

      expect(subject.errors).to be_empty
    end
  end
end
