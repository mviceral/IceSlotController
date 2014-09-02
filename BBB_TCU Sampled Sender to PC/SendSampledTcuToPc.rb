require 'sqlite3'
require 'rest_client'
require 'singleton'
require 'forwardable'
require_relative '../BBB_Shared Memory Ruby/SharedMemory'
require_relative 'SendSampledTcuToPcLib'

SendSampledTcuToPCLib.RunSender
