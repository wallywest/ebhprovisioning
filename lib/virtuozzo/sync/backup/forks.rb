require_relative 'init'
require_relative 'emsync'
10.times do
    Sync::run(@config)
end
