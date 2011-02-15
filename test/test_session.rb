require 'helper'

class TestSession < ActiveSupport::TestCase
  context "A SugarCRM::Session instance" do
    should "load monkey patch extensions" do
      SugarCRM.session.extensions_folder = File.join(File.dirname(__FILE__), 'extensions_test')
      assert SugarCRM::Contact.is_extended?
      assert SugarCRM::Contact.is_extended?
    end
    
    should "implement reload!" do
      assert_nothing_raised do
        SugarCRM.session.reload!
      end
    end
    
    should "load config file" do
      SugarCRM.session.load_config File.join(File.dirname(__FILE__), 'config_test.yaml')
      
      config_contents = { 
        :config => {
                      :base_url => 'http://127.0.0.1/sugarcrm',
                      :username => 'admin',
                      :password => 'letmein'
                   }
      }
      
      config_contents[:config].each{|k,v|
        assert_equal v, SugarCRM.session.config[k]
      }
    end
    
    should "assign namespaces in a way that prevents collisions" do
      # Namespae0 already assigned (linked to the current connection)
      One = SugarCRM::Session.new_from_file(CONFIG_PATH)
      Two = SugarCRM::Session.new_from_file(CONFIG_PATH)
      One.session.disconnect!
      Three = SugarCRM::Session.new_from_file(CONFIG_PATH)
      
      assert_not_equal Two, Three # namespaces must be different
      Two.session.disconnect!
      Three.session.disconnect!
    end
    
    should "be able to disconnect, and log in to Sugar automatically if credentials are present in config file" do
      assert_nothing_raised{ SugarCRM.current_user }
      assert SugarCRM.sessions.size == 1
      
      SugarCRM.session.disconnect!
      assert SugarCRM.sessions.size == 0
      
      assert_raise(SugarCRM::NoActiveSession){ SugarCRM.current_user }
      
      SugarCRM::Session.new_from_file(CONFIG_PATH)
      
      assert_nothing_raised{ SugarCRM.current_user }
      assert SugarCRM.sessions.size == 1
    end
    
    should "update the login credentials on connection" do
      config = YAML.load_file(CONFIG_PATH) # was loaded in helper.rb
      ["base_url", "username", "password"].each{|k|
        assert_equal config["config"][k], SugarCRM.session.config[k.to_sym]
      }
    end
    
    should "return the server version" do
      assert_equal String, SugarCRM.session.sugar_version.class
    end
  end
  
  context "The SugarCRM module" do
    should "show the only the namespaces currently in use with SugarCRM.namespaces" do
      assert_equal 1, SugarCRM.namespaces.size
      
      assert_difference('SugarCRM.namespaces.size') do
        OneA = SugarCRM::Session.new_from_file(CONFIG_PATH)
      end
      
      assert_difference('SugarCRM.namespaces.size', -1) do
        OneA.session.disconnect!
      end
    end
    
    should "add a used namespace on each new connection" do
      assert_difference('SugarCRM.used_namespaces.size') do
        OneB = SugarCRM::Session.new_from_file(CONFIG_PATH)
      end
      
      # connection (and namespace) is reused => no used namespace should be added
      assert_no_difference('SugarCRM.used_namespaces.size') do
        OneB.session.reconnect!
      end
      
      assert_no_difference('SugarCRM.used_namespaces.size') do
        OneB.session.disconnect!
      end
    end
  end
end