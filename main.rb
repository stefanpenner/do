#!/usr/bin/env ruby
# encoding: utf-8

require 'digitalocean'
require 'ap'
require 'spinner.rb'

Digitalocean.client_id = ENV['DIGITAL_OCEAN_CLIENT_ID'] or abort('missing DIGITAL_OCEAN_CLIENT_ID')
Digitalocean.api_key   = ENV['DIGITAL_OCEAN_API_KEY']   or abort('missing DIGITAL_OCEAN_API_KEY')

command = ARGV[0]
name    = ARGV[1]

# Create a new spinner instance
def by_name(name)
  Digitalocean::Droplet.all.droplets.find do |droplet|
    droplet.name == name
  end
end

def details(droplet, event)
  {
    name: droplet.name,
    id: droplet.id,
    droplet: droplet.status,
    event: event && event.status
  }
end

def wait(droplet, status)
  abort 'no such droplet' unless droplet

  first = true
  spinner = Spinner.new
  spinner.task("waiting for #{droplet.name}.status: #{droplet.status} to become: #{status}") do
    begin
      sleep 5 unless first
      first = false
      droplet = Digitalocean::Droplet.find(droplet.id).droplet
      waiting = droplet.status === status
    end while not waiting
  end
  spinner.spin!
end

def help
  abort <<-HELP
drop:
  ip  <name>
  off <name>
  on  <name>
  status
HELP
end

help unless command

def serialize(droplet)
  {
    id: droplet.id,
    name: droplet.name,
    status: droplet.status,
    ip: droplet.ip_address
  }
end

case command.downcase.to_sym
when :status then
  if name
    ap serialize(by_name(name))
  else
    Digitalocean::Droplet.all.droplets.each do |droplet|
      ap serialize(droplet)
    end
  end
when :ip then
  droplet = by_name(name)
  abort 'no such droplet' unless droplet
  puts droplet.ip_address
when :off then
  droplet = by_name(name)
  abort 'no such droplet' unless droplet
  event = Digitalocean::Droplet.shutdown(droplet.id)
  wait(droplet, 'off')
when :on then
  droplet = by_name(name)
  abort 'no such droplet' unless droplet
  event = Digitalocean::Droplet.power_on(droplet.id)
  ap details(droplet, event)
when :wait then
  wait(by_name(name), ARGV[2])
else
  puts "unknown command #{command}"
  help
end
