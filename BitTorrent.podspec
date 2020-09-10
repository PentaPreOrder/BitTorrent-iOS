Pod::Spec.new do |s|

  s.name             = 'BitTorrent'
  s.version          = '1.1.14'
  s.summary          = 'Built library "libtorrent.a" and dependent header files for iOS.'
  s.homepage         = 'https://www.github.com'
  s.license          = { :type => 'MIT', :text => 'LICENSE' }
  s.author           = { 'xinglei' => 'preorder@qq.com' }
  s.source           = { :git => 'git@github.com:PentaPreOrder/BitTorrent-iOS.git', :tag => s.version.to_s }
  s.libraries        = 'c++'
  s.platform         = :ios, '8.0'

  s.header_mappings_dir = 'include'
  s.public_header_files = 'include/**/*.{h,hpp,ipp}'
  s.source_files = 'include/**/*.{h,hpp,ipp}'
  s.vendored_libraries = 'libs/*.a'

end
