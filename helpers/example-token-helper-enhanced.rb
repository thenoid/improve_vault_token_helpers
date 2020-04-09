#!/usr/bin/env ruby
# Enahnced from https://www.vaultproject.io/docs/commands/token-helper

require 'json'

unless ENV['VAULT_ADDR']
  STDERR.puts "No VAULT_ADDR environment variable set. Set it and run me again!"
  exit 100
end

addr = ( ENV['VAULT_ADDR'] ? ENV['VAULT_ADDR'] : 'default');
ns = ( ENV['VAULT_NAMESPACE'] ? ENV['VAULT_NAMESPACE'] : 'root');
modifier = ( ENV['VAULT_MOD'] ? ENV['VAULT_MOD'] : 'default');
token_file = ( ENV['VAULT_TOKEN_FILE'] ? ENV['VAULT_TOKEN_FILE'] : "#{ENV['HOME']}/.vault.d/vault_tokens");

begin
  tokens = JSON.parse(File.read(token_file))
rescue Errno::ENOENT => e
  # file doesn't exist so create a blank hash for it
  tokens = {}
end

tokens[modifier] = {} unless tokens[modifier];
tokens[modifier][ns] = {} unless tokens[modifier][ns];

case ARGV.first
when 'get'
  print tokens[modifier][ns][addr] if tokens[modifier][ns][addr]
  exit 0
when 'store'
  tokens[modifier][ns][addr] = STDIN.read
when 'erase'
  tokens[modifier][ns].delete!(addr)
end

File.open(token_file, 'w') { |file| file.write(tokens.to_json) }