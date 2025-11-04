require 'xcodeproj'

project_path = 'Pods/Pods.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  if target.name == 'BoringSSL-GRPC'
    puts "Found BoringSSL-GRPC target, fixing build settings..."
    target.build_configurations.each do |config|
      # The fix: set GCC_WARN_INHIBIT_ALL_WARNINGS to NO (not YES!)
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'NO'
      puts "Fixed #{config.name} configuration - set GCC_WARN_INHIBIT_ALL_WARNINGS to NO"
    end
  end
end

project.save
puts "Done!"
