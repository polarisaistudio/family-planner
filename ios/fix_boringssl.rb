require 'xcodeproj'

project_path = 'Pods/Pods.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  if target.name == 'BoringSSL-GRPC'
    puts "Found BoringSSL-GRPC target, fixing build settings..."
    target.build_configurations.each do |config|
      # Remove the -G flag by disabling debug symbol generation
      config.build_settings['GCC_GENERATE_DEBUGGING_SYMBOLS'] = 'NO'
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
      config.build_settings['WARNING_CFLAGS'] = '-w'
      config.build_settings['OTHER_CFLAGS'] = ['-w']
      puts "Fixed #{config.name} configuration"
    end
  end
end

project.save
puts "Done!"
