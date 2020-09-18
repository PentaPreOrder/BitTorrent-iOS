Pod::Spec.new do |s|

  s.name             = 'BitTorrent'
  s.version          = '1.1.14'
  s.summary          = 'Built library "libtorrent.a" and dependent header files for iOS.'
  s.homepage         = 'https://www.github.com'
  s.license          = { :type => 'MIT', :text => 'LICENSE' }
  s.author           = { 'xinglei' => 'preorder@qq.com' }
  s.source           = { :git => 'git@gitee.com:preorder/BitTorrent-iOS.git', :tag => "mirror_#{s.version}" }
  s.libraries        = 'c++'
  s.platform         = :ios, '8.0'

  s.default_subspecs = 'Core'
  s.subspec 'Core' do |c|
    c.header_mappings_dir = 'include'
    c.public_header_files = 'include/**/*.{h,hpp,ipp}'
    c.source_files = 'include/**/*.{h,hpp,ipp}'
    c.vendored_libraries = 'libs/*.a'
  end

  s.subspec 'Downloader' do |d|
    d.public_header_files = 'BitTorrent/Classes/**/*.{h}'
    d.source_files = 'BitTorrent/Classes/**/*.{h,mm}'
    d.preserve_paths = 'include'
    d.vendored_libraries = 'libs/*.a'
    d.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/BitTorrent/include"'
    }
  end

end
