require 'rake'

require_relative 'common'
require_relative 'git'

require_relative 'dropbox_deploy'
require_relative 'dropbox_deploy_credentials'

include Common

task :init do

  $git_repo         = 'https://github.com/ArduboyGameDevelopers/PixelSpaceOdyssey.git'
  $git_branch       = 'feature/level_editor'

  $project_name     = 'PixelSpaceOdyssey'
  $project_config   = 'Release'

  $dir_builder      = File.expand_path '.'
  $dir_project      = "#{$dir_repo}/#{$project_name}"

  $dir_out          = "#{$dir_builder}/out"
  $dir_out_builds   = "#{$dir_out}/builds"

  $dir_repo         = "#{$dir_out}/repo"

  $dir_emu          = "#{$dir_repo}/Emulator"
  $dir_emu_build    = "#{$dir_emu}/build"
  $file_emu_project = "#{$dir_emu}/Emulator.pro"

end

task :clean => :init do
  FileUtils.rm_rf $dir_emu_build
  FileUtils.rm_rf $dir_out
end

task :clone_repo => :clean do
  Git.clone $git_repo, $git_branch, $dir_repo
end

desc 'Build the app'
task :build => :clone_repo do

  def extract_project_version(dir_project)
    file_plist = resolve_path "#{dir_project}/Version.h"
    source = File.read file_plist
    source =~ /#define\s+PROJECT_VERSION\s+"(\d+\.\d+\.\d+)"/

    not_nil $1
  end

  project_version = extract_project_version $dir_emu

  puts "Project version: #{project_version}"

  # create directory
  dir_build = "#{$dir_emu_build}/#{$project_config}"
  make_dir dir_build, :overwrite => true

  # build make project
  Dir.chdir dir_build do
    exec_shell %(qmake "#{$file_emu_project}" -r -spec win32-g++ "CONFIG+=#{$project_config.downcase}), "Can't run qmake"
  end

  # run make project
  file_makefile = "Makefile.#{$project_config}"

  Dir.chdir dir_build do
    exec_shell %(mingw32-make -f "#{file_makefile}"), "Can't run make"
  end

  # deploy windows
  file_app = resolve_path "#{dir_build}/#{$project_config.downcase}/Emulator.exe"
  dir_deploy = "#{$dir_out}/deploy"

  make_dir dir_deploy, :overwrite => true
  FileUtils.cp file_app, "#{dir_deploy}/"

  Dir.chdir dir_deploy do
    cmd = ''
    cmd << 'windeployqt'
    cmd << " --#{$project_config.downcase}"
    cmd << ' --no-translations'
    cmd << ' --no-quick-import'
    cmd << ' --no-system-d3d-compiler'
    cmd << ' --no-angle'
    cmd << ' Emulator.exe'
    exec_shell cmd, "Can't deploy windows"

    trash_files = %w(iconengines imageformats opengl32sw.dll Qt5Svg.dll)

    trash_files.each do |file|
      if File.directory? file
        FileUtils.rm_rf file
      else
        FileUtils.rm file
      end
    end

  end

  # copy tiles
  FileUtils.cp_r "#{$dir_emu}/Tiles", "#{dir_deploy}/"

  # zip delivery

  make_dir $dir_out_builds, :overwrite => true

  file_build = "#{$dir_out_builds}/#{$project_name}-#{project_version}.zip"
  zip_dir dir_deploy, file_build

end

desc 'Deploys the app'
task :deploy => :build do

  file_build = resolve_path Dir["#{$dir_out_builds}/#{$project_name}-*.zip"].first

  dropbox = DropboxDeploy.new $dropbox_access_token
  dropbox.deploy file_build

end
