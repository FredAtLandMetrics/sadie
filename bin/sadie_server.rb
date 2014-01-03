#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'sadie_server'
require 'pp'
arghash = SadieServer::proc_args( ARGV )
puts "arghash: #{arghash.pretty_inspect}"
require 'sinatra'

server = SadieServer.new( arghash )

get '/:key' do
  server.get params[:key]
end

post '/:key' do
  server.set params[:key], params[:value]
end

# FUTURE
# post '/query' do
#   server.query params[:query]
# end

