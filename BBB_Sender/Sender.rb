require 'sqlite3'
require 'rest_client'
require 'singleton'
require 'forwardable'
require_relative '../lib/SharedMemory'
require_relative 'SendSampledTcuToPcLib'

SendSampledTcuToPCLib.RunSender
