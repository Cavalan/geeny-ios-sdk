#!/usr/bin/env ruby

require 'fileutils'

#########################################################################################
# This script provides an workaround to generate Jazzy documentation with
# non-public dependencies (currently Moscapsule).
#
# Jazzy reads podspec to get dependency info, but since Podspec (in contrary to Podfile)
# doesn't support private pods, Jazzy doesn't support it directly either.
# See also: https://github.com/realm/jazzy/issues/650
#
# Interestingly Jazzy doesn't really need this dependency to work.
# So this script temporarily removes this dependency from the Podspec, run Jazzy,
# and then restore the original Podspec.
#
# Feel free to find out some better ways!
#########################################################################################

gateway_podspec_path = "../GeenyGateway.podspec"
gateway_podspec_bak_path = "#{gateway_podspec_path}.bak"
jazzy_config_path = "../GeenyGateway/.jazzy.yaml"

# Backup
puts "[GEENY] Backing-up original Podspec"
FileUtils.cp(gateway_podspec_path, gateway_podspec_bak_path)

# Comment out Moscapsule dependency
lines = IO.readlines(gateway_podspec_path).map do |line|
  if line.include?("Moscapsule")
    puts "[GEENY] Disabling Moscapsule until it's a public Pod"
    "#  #{line}"
  else
    line
  end
end

# Store the temporary podspec
puts "[GEENY] Modifying Podspec"
File.open(gateway_podspec_path, 'w') do |file|
  file.puts lines
end

# Run jazzy
puts "[GEENY] Invoking Jazzy"
jazzy_command = "jazzy --config #{jazzy_config_path}"
system jazzy_command

# Restore backup
puts "[GEENY] Restoring original Podspec"
FileUtils.cp(gateway_podspec_bak_path, gateway_podspec_path)
FileUtils.rm(gateway_podspec_bak_path)
