# Load the rails application
require File.expand_path('../application', __FILE__)

require 'rake'
module ::FleerAndTaker
    class Application
        include Rake::DSL
    end
end

module ::RakeFileUtils
    extend Rake::FileUtilsExt
end

# Initialize the rails application
FleerAndTaker::Application.initialize!
