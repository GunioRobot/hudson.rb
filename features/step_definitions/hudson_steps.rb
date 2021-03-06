Given /^I have a Hudson server running$/ do
  unless @hudson_port
    port = 3010
    begin
      res = Net::HTTP.start("localhost", port) { |http| http.get('/api/json') }
      Hudson::Api.base_uri "http://localhost:#{port}"
    rescue Errno::ECONNREFUSED => e
      raise Exception, "To run tests, launch hudson in test mode: 'rake hudson:server:test'"
    end
    @hudson_port = port.to_s
    @hudson_host = 'localhost'
  end
end

Given /^the Hudson server has no current jobs$/ do
  if port = @hudson_port
    Hudson::Api.summary['jobs'].each do |job|
      Hudson::Api.delete_job(job['name'])
    end
    Hudson::Api.summary['jobs'].should == []
  else
    puts "WARNING: Run 'I have a Hudson server running' step first."
  end
end

Given /^the Hudson server has no slaves$/ do
  if port = @hudson_port
    Hudson::Api.summary['jobs'].each do |job|
      Hudson::Api.delete_job(job['name'])
    end
    Hudson::Api.summary['jobs'].should == []

    Hudson::Api.nodes['computer'].each do |node|
      name = node['displayName']
      Hudson::Api.delete_node(name) unless name == "master"
    end
    Hudson::Api.nodes['computer'].size.should == 1
  else
    puts "WARNING: Run 'I have a Hudson server running' step first."
  end
end

Given /^there is nothing listening on port (\d+)$/ do |port|
  lambda {
    TCPSocket.open("localhost", port) {}
  }.should raise_error
end

Given /^I cleanup any hudson processes with control port (\d+)$/ do |port|
  @hudson_cleanup << port
end

def try(times, interval = 1)
  begin
    times -= 1
    return yield
  rescue Exception => e
    if times >= 0
      sleep(interval)
      retry
    end
    raise e
  end
end

When /^I run hudson server with arguments "(.*)"/ do |arguments|
  @stdout = File.expand_path(File.join(@tmp_root, "executable.out"))
  executable = File.expand_path(File.join(File.dirname(__FILE__), "/../../bin","hudson"))
  in_project_folder do
    system "ruby #{executable.inspect} server #{arguments} > #{@stdout.inspect} 2> #{@stdout.inspect}"
  end
end


Then /^I should see a hudson server on port (\d+)$/ do |port|
  require 'json'
  try(15, 2) do
    Hudson::Api.base_uri "http://localhost:#{port}"
    Hudson::Api.summary['nodeDescription'].should == "the master Hudson node"
  end
end

When /^I (re|)create a job$/ do |override|
  override = override.blank? ? "" : " --override"
  steps <<-CUCUMBER
    When the project uses "git" scm
    When I run local executable "hudson" with arguments "create . --host localhost --port 3010#{override}"
  CUCUMBER
end

Then /^the job "([^"]*)" config "([^"]*)" should be:$/ do |job_name, xpath, string|
  raise "Cannot yet fetch XML config from non-localhost Hudson" unless Hudson::Api.base_uri =~ /localhost/
  require "hpricot"
  config = Hpricot.XML(File.read("#{test_hudson_path}/jobs/#{job_name}/config.xml"))
  config.search(xpath).to_s.should == string
end

Then /^the Hudson config "([^"]*)" should be:$/ do |xpath, string|
  raise "Cannot yet fetch XML config from non-localhost Hudson" unless Hudson::Api.base_uri =~ /localhost/
  require "hpricot"
  config = Hpricot.XML(File.read("#{test_hudson_path}/config.xml"))
  config.search(xpath).to_s.should == string
end

