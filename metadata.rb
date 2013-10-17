name             'chef-server-etcd'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 's.renatus@cloudbau.de'
license          'Apache 2.0'
description      'Wrapper for using `chef-server` cookbook with etcd-chef'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'chef-server' # the non-embedded chef-server cookbook
depends 'runit'       # the embedded runit cookbook
