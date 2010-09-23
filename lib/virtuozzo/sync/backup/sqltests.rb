require_relative 'init'
require_relative 'ippool'
require 'active_record'
@ips=Vdspool.where("veid='20167'").select("ips")
@pool=Virtuozzo::IPool::new
p @pool.cclass
@pool.cclass={"hello"=>"hello"}
p @pool.cclass
Virtuozzo::IPool::giveips(@ips.first.ips)
