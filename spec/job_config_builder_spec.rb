require File.dirname(__FILE__) + "/spec_helper"

describe Hudson::JobConfigBuilder do
  include ConfigFixtureLoaders
  
  describe "explicit steps to match a ruby job" do
    before do
      @config = Hudson::JobConfigBuilder.new do |c|
        c.scm = "git://codebasehq.com/mocra/misc/mocra-web.git"
        c.steps = [
          [:build_shell_step, "bundle install"],
          [:build_shell_step, "bundle exec rake"]
        ]
      end
    end
    it "builds config.xml" do
      config_xml("ruby", "single").should == @config.to_xml
    end
  end
  
  
  describe "rails job; single axis" do
    before do
      @config = Hudson::JobConfigBuilder.new(:rails) do |c|
        c.scm = "git://codebasehq.com/mocra/misc/mocra-web.git"
      end
    end
    it "builds config.xml" do
      config_xml("rails", "single").should == @config.to_xml
    end
  end
  
  
  
  describe "rubygem job; single axis" do
    before do
      @config = Hudson::JobConfigBuilder.new(:rubygem) do |c|
        c.scm = "http://github.com/drnic/picasa_plucker.git"
      end
    end
    it "builds config.xml" do
      config_xml("rubygem").should == @config.to_xml
    end
  end
  
  describe "assigned slave nodes for slave usage" do
    before do
      @config = Hudson::JobConfigBuilder.new(:rails) do |c|
        c.assigned_node = "my-slave"
      end
    end
    it "builds config.xml" do
      Hpricot.XML(@config.to_xml).search("assignedNode").size.should == 1
      Hpricot.XML(@config.to_xml).search("assignedNode").text.should == "my-slave"
      Hpricot.XML(@config.to_xml).search("canRoam").text.should == "false"
    end
  end
  
  describe "no specific slave nodes" do
    before do
      @config = Hudson::JobConfigBuilder.new(:rails) do |c|
      end
    end
    it "builds config.xml" do
      Hpricot.XML(@config.to_xml).search("assignedNode").size.should == 0
    end
  end
  
  describe "public_scm = true => convert git@ into git:// until we have deploy keys" do
    before do
      @config = Hudson::JobConfigBuilder.new(:rails) do |c|
        c.scm = "git@codebasehq.com:mocra/misc/mocra-web.git"
        c.public_scm = true
      end
    end
    it "builds config.xml" do
      config_xml("rails", "single").should == @config.to_xml
    end
  end

  describe "setup ENV variables via envfile plugin" do
    before do
      @config = Hudson::JobConfigBuilder.new(:rails) do |c|
        c.scm      = "git://codebasehq.com/mocra/misc/mocra-web.git"
        c.steps    = []
        c.envfile  = "/path/to/env/file"
      end
    end
    it "builds config.xml" do
      xml_bite = <<-XML.gsub(/^      /, '')
      <buildWrappers>
          <hudson.plugins.envfile.EnvFileBuildWrapper>
            <filePath>/path/to/env/file</filePath>
          </hudson.plugins.envfile.EnvFileBuildWrapper>
        </buildWrappers>
      XML
      Hpricot.XML(@config.to_xml).search("buildWrappers").to_s.should == xml_bite.strip
    end
  end
end