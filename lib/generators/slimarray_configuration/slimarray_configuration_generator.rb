class SlimarrayConfigurationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      require 'highline/import'
      HighLine.track_eof = false

      dev_mysql_server = ask_or_nil("Development MySQL Server [localhost]: ")
      dev_mysql_database = ask_or_nil("Development MySQL Database [slimarray_dev]: ")
      dev_mysql_username = ask_or_nil("Development MySQL username [slimarray]: ")
      dev_mysql_password = ask_or_nil("Development MySQL password [slimarray]: ")

      test_mysql_server = ask_or_nil("Test MySQL Server [localhost]: ")
      test_mysql_database = ask_or_nil("Test MySQL Database [slimarray_dev]: ")
      test_mysql_username = ask_or_nil("Test MySQL username [slimarray]: ")
      test_mysql_password = ask_or_nil("Test MySQL password [slimarray]: ")

      if ARGV[0] == "slimcore"
        rubycas_server = ask_or_nil("RubyCAS Server Address [http://localhost:3020]: ")
        slimcore_site = ask_or_nil("SLIMcore Address [http://localhost:3030]: ")
        slimcore_user = ask_or_nil("SLIMcore User [slimbot]: ")
        slimcore_password = ask_or_nil("SLIMcore Password [test]: ")

        slimcore_dev_mysql_server = ask_or_nil("SLIMcore Development MySQL Server [localhost]: ")
        slimcore_dev_mysql_database = ask_or_nil("SLIMcore Development MySQL Database [slimcore_dev]: ")
        slimcore_dev_mysql_username = ask_or_nil("SLIMcore Development MySQL username [slimcore]: ")
        slimcore_dev_mysql_password = ask_or_nil("SLIMcore Development MySQL password [slimcore]: ")

        slimcore_test_mysql_server = ask_or_nil("SLIMcore Test MySQL Server [localhost]: ")
        slimcore_test_mysql_database = ask_or_nil("SLIMcore Test MySQL Database [slimcore_test]: ")
        slimcore_test_mysql_username = ask_or_nil("SLIMcore Test MySQL username [slimcore]: ")
        slimcore_test_mysql_password = ask_or_nil("SLIMcore Test MySQL password [slimcore]: ")
      end

      m.template "application.yml.erb", "config/application.yml", :assigns => {
        :rubycas_server => rubycas_server,
      }
      m.template "database.yml.erb", "config/database.yml", :assigns => {
        :dev_mysql_server => dev_mysql_server,
        :dev_mysql_database => dev_mysql_database,
        :dev_mysql_username => dev_mysql_username,
        :dev_mysql_password => dev_mysql_password,

        :test_mysql_server => test_mysql_server,
        :test_mysql_database => test_mysql_database,
        :test_mysql_username => test_mysql_username,
        :test_mysql_password => test_mysql_password,

        :slimcore_dev_mysql_server => slimcore_dev_mysql_server,
        :slimcore_dev_mysql_database => slimcore_dev_mysql_database,
        :slimcore_dev_mysql_username => slimcore_dev_mysql_username,
        :slimcore_dev_mysql_password => slimcore_dev_mysql_password,

        :slimcore_test_mysql_server => slimcore_test_mysql_server,
        :slimcore_test_mysql_database => slimcore_test_mysql_database,
        :slimcore_test_mysql_username => slimcore_test_mysql_username,
        :slimcore_test_mysql_password => slimcore_test_mysql_password
      }
    end
  end

  def ask_or_nil(question)
    response = ask(question)
    response == "" ? nil : response
  end
end
