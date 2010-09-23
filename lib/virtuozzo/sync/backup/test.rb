require 'xmlsimple'
require_relative 'init'
require_relative 'sync'
@file=File.join(File.dirname(__FILE__),'config.xml')
@config=XmlSimple.xml_in(@file)
Virtuozzo::Sync::run(@config)
#Virtuozzo::IPool::gimme "Pro","2"
