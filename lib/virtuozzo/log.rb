require 'log4r'
require 'logger'
include Log4r
$path=File.join(File.dirname(__FILE__),'..','log')
module Virtuozzo
	class Log
		class <<self
			def create(file)
				@file=file
				@log=Log4r::Logger.new(@file)
				p=PatternFormatter.new(:pattern => "[ %d ] %l\t %m")
				Log4r::FileOutputter.new('logfile',
	                          :filename=>"#{$path}/#{@file}",
	                          :trunc=>false,
				  :formatter=>p,
				  :level => Log4r::INFO
	                          )
				@log.add('logfile')
			end
			def write(message)
				@log.info "#{message}"
			end
			def error(message)
				@log.error "ERROR: #{message}"
			end
		end
	end
end
