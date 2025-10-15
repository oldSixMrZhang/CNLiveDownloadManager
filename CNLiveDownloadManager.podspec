
Pod::Spec.new do |s|
  s.name             = 'CNLiveDownloadManager'
  s.version          = '0.0.4'
  s.summary          = '下载管理器'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://bj.gitlab.cnlive.com/ios-team/CNLiveDownloadManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '殷巧娟' => '1427945373@qq.com' }
  s.source           = { :git => 'http://bj.gitlab.cnlive.com/ios-team/CNLiveDownloadManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  # s.source_files = 'CNLiveDownloadManager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CNLiveDownloadManager' => ['CNLiveDownloadManager/Assets/*.png']
  # }
  
  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.subspec 'Model' do |model|
      model.dependency 'CNLiveBaseKit'
      model.dependency 'CNLiveTripartiteManagement/FMDB'
      model.source_files = 'CNLiveDownloadManager/Classes/Model/*.{h,m}'
  end
  s.subspec 'ViewModel' do |viewModel|
      viewModel.dependency 'CNLiveTripartiteManagement/FMDB'
      viewModel.source_files = 'CNLiveDownloadManager/Classes/ViewModel/*.{h,m}'
      viewModel.dependency 'CNLiveDownloadManager/Model'
      viewModel.dependency 'CNLiveBaseTools'
      viewModel.dependency 'CNLiveEnvironmentConfiguration'
      viewModel.dependency 'CNLiveBusinessTools'
      viewModel.dependency 'CNLiveBaseKit'
      viewModel.dependency 'CNLiveRequestBastKit'
      viewModel.dependency 'CNLiveTripartiteManagement/QMUIKit'
  end
  s.frameworks = 'UIKit', 'Foundation'
  # s.dependency 'CNLiveTripartiteManagement/FMDB'
  # s.dependency 'CNLiveBaseKit'
  # s.dependency 'CNLiveTripartiteManagement/MJExtension'
end
