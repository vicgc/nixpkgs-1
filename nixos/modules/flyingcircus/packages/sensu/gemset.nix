{
  activesupport = {
    dependencies = ["i18n" "json" "minitest" "thread_safe" "tzinfo"];
    source = {
      sha256 = "1w2znchjbgzj3sgp0581q15rikcj1cji80ki2ky8fwdnjxlh54mb";
      type = "gem";
    };
    version = "4.2.5";
  };
  amq-protocol = {
    source = {
      sha256 = "1gl479j003vixfph5jmdskl20il8816y0flp4msrc8im3b5iiq3r";
      type = "gem";
    };
    version = "1.9.2";
  };
  amqp = {
    dependencies = ["amq-protocol" "eventmachine"];
    source = {
      sha256 = "0jlcwyvjz0b28wxdabkyhdqyqp5ji56ckfywsy9mgp0m4wfbrh8c";
      type = "gem";
    };
    version = "1.5.0";
  };
  async_sinatra = {
    dependencies = ["rack" "sinatra"];
    source = {
      sha256 = "0sjdvkchq5blvfdahhrlipsx5sr9kfmdx0zxssjlfkz54dbl14m0";
      type = "gem";
    };
    version = "1.2.0";
  };
  aws = {
    dependencies = ["http_connection" "uuidtools" "xml-simple"];
    source = {
      sha256 = "0fmlilz3gxml4frf5q0hnvrw9xfr7zhwfmac3f5k63czdf5qdzrc";
      type = "gem";
    };
    version = "2.10.2";
  };
  aws-es-transport = {
    dependencies = ["aws-sdk" "elasticsearch" "faraday" "faraday_middleware"];
    source = {
      sha256 = "1r2if0jcbw3xx019fs6lqkz65nffwgh7hjbh5fj13hi09g505m3m";
      type = "gem";
    };
    version = "0.1.4";
  };
  aws-sdk = {
    dependencies = ["aws-sdk-resources"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0wxvkzn7nsp5r09z3428cmzzzpkjdqmcwgwsfmm3clb93k9ivchv";
      type = "gem";
    };
    version = "2.4.4";
  };
  aws-sdk-core = {
    dependencies = ["jmespath"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0v624h6yv28vbmcskx6n67blzq2an0171wcppkr3sx335wi4hriw";
      type = "gem";
    };
    version = "2.4.4";
  };
  aws-sdk-resources = {
    dependencies = ["aws-sdk-core"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1a1lxkig0d2ihv8f581nq65z4b2cf89mg753mvkh8b1kh9ipybx4";
      type = "gem";
    };
    version = "2.4.4";
  };
  bson = {
    source = {
      sha256 = "0r8h83d4wh9yi1r80hz91as6nc2b0yl6xarmfxjrdrzl7mdgcyx6";
      type = "gem";
    };
    version = "1.12.3";
  };
  bson_ext = {
    dependencies = ["bson"];
    source = {
      sha256 = "1wyfasc304spafd5mm9hv195vinh79yrbdq8yym4s7xry9rbifcy";
      type = "gem";
    };
    version = "1.12.3";
  };
  childprocess = {
    dependencies = ["ffi"];
    source = {
      sha256 = "1lv7axi1fhascm9njxh3lx1rbrnsm8wgvib0g7j26v4h1fcphqg0";
      type = "gem";
    };
    version = "0.5.8";
  };
  concurrent-ruby = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "183lszf5gx84kcpb779v6a2y0mx9sssy8dgppng1z9a505nj1qcf";
      type = "gem";
    };
    version = "1.0.5";
  };
  daemons = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0lxqq6dgb8xhliywar2lvkwqy2ssraf9dk4b501pb4ixc2mvxbp2";
      type = "gem";
    };
    version = "1.2.6";
  };
  dentaku = {
    source = {
      sha256 = "18ga010bbhsgc876vf6z6swfnk2mgj30y96rcd4yafvmwnj5djgz";
      type = "gem";
    };
    version = "2.0.4";
  };
  dnsbl-client = {
    source = {
      sha256 = "1357r0y8xfnay05l9h26rrcqrjlnz0hy421g18pfrwm1psf3pp04";
      type = "gem";
    };
    version = "1.0.2";
  };
  dnsruby = {
    source = {
      sha256 = "0vf1940vxh3f387b1albb7r90zxrybaiw8094hf5z4zxc97ys7dj";
      type = "gem";
    };
    version = "1.58.0";
  };
  domain_name = {
    dependencies = ["unf"];
    source = {
      sha256 = "12hs8yijhak7p2hf1xkh98g0mnp5phq3mrrhywzaxpwz1gw5r3kf";
      type = "gem";
    };
    version = "0.5.20170404";
  };
  elasticsearch = {
    dependencies = ["elasticsearch-api" "elasticsearch-transport"];
    source = {
      sha256 = "1wdy17i56b4m7akp7yavnr8vhfhyz720waphmixq05dj21b11hl0";
      type = "gem";
    };
    version = "1.0.18";
  };
  elasticsearch-api = {
    dependencies = ["multi_json"];
    source = {
      sha256 = "1v6nb3ajz5rack3p4b4nz37hs0zb9x738h2ms8cc4plp6wqh1w5s";
      type = "gem";
    };
    version = "1.0.18";
  };
  elasticsearch-transport = {
    dependencies = ["faraday" "multi_json"];
    source = {
      sha256 = "0smfrz8nq49hgf67y5ayxa9i4rmmi0q4m51l0h499ykq4cvcwv6i";
      type = "gem";
    };
    version = "1.0.18";
  };
  em-redis-unified = {
    dependencies = ["eventmachine"];
    source = {
      sha256 = "0rzf2c2cbfc1k5jiahmgd3c4l9z5f74b6a549v44n5j1hyj03m9v";
      type = "gem";
    };
    version = "1.0.1";
  };
  em-worker = {
    dependencies = ["eventmachine"];
    source = {
      sha256 = "0z4jx9z2q5hxvdvik4yp0ahwfk69qsmdnyp72ln22p3qlkq2z5wk";
      type = "gem";
    };
    version = "0.0.2";
  };
  erubis = {
    source = {
      sha256 = "1fj827xqjs91yqsydf0zmfyw9p4l2jz5yikg3mppz6d7fi8kyrb3";
      type = "gem";
    };
    version = "2.7.0";
  };
  eventmachine = {
    source = {
      sha256 = "17jr1caa3ggg696dd02g2zqzdjqj9x9q2nl7va82l36f7c5v6k4z";
      type = "gem";
    };
    version = "1.0.9.1";
  };
  faraday = {
    dependencies = ["multipart-post"];
    source = {
      sha256 = "1kplqkpn2s2yl3lxdf6h7sfldqvkbkpxwwxhyk7mdhjplb5faqh6";
      type = "gem";
    };
    version = "0.9.2";
  };
  faraday_middleware = {
    dependencies = ["faraday"];
    source = {
      sha256 = "18jndnpls6aih57rlkzdq94m5r7zlkjngyirv01jqlxll8jy643r";
      type = "gem";
    };
    version = "0.10.1";
  };
  ffi = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0zw6pbyvmj8wafdc7l5h7w20zkp1vbr2805ql5d941g2b20pk4zr";
      type = "gem";
    };
    version = "1.9.23";
  };
  http-cookie = {
    dependencies = ["domain_name"];
    source = {
      sha256 = "004cgs4xg5n6byjs7qld0xhsjq3n6ydfh897myr2mibvh6fjc49g";
      type = "gem";
    };
    version = "1.0.3";
  };
  http_connection = {
    source = {
      sha256 = "0gj3imp4yyys5x2awym1nwy5qandmmpsjpf66m76d0gxfd4zznk9";
      type = "gem";
    };
    version = "1.4.4";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "038qvz7kd3cfxk8bvagqhakx68pfbnmghpdkx7573wbf0maqp9a3";
      type = "gem";
    };
    version = "0.9.5";
  };
  inifile = {
    source = {
      sha256 = "1c5zmk7ia63yw5l2k14qhfdydxwi1sah1ppjdiicr4zcalvfn0xi";
      type = "gem";
    };
    version = "3.0.0";
  };
  jmespath = {
    source = {
      sha256 = "07w8ipjg59qavijq59hl82zs74jf3jsp7vxl9q3a2d0wpv5akz3y";
      type = "gem";
    };
    version = "1.3.1";
  };
  json = {
    source = {
      sha256 = "0qmj7fypgb9vag723w1a49qihxrcf5shzars106ynw2zk352gbv5";
      type = "gem";
    };
    version = "1.8.6";
  };
  libxml-ruby = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1r7m7zipkpam8ns4ys4qyh7yj3is3dy7ky6qwnw557pvpgx0aqrd";
      type = "gem";
    };
    version = "3.1.0";
  };
  libxml-xmlrpc = {
    dependencies = ["libxml-ruby"];
    source = {
      sha256 = "0xqp6j529aa2ygp8xrlz9a0pnh64x458jr4pywqanfw7i64a3qdb";
      type = "gem";
    };
    version = "0.1.5";
  };
  mail = {
    dependencies = ["mime-types"];
    source = {
      sha256 = "1nbg60h3cpnys45h7zydxwrl200p7ksvmrbxnwwbpaaf9vnf3znp";
      type = "gem";
    };
    version = "2.6.3";
  };
  mailgun-ruby = {
    dependencies = ["json" "rest-client"];
    source = {
      sha256 = "1aqa0ispfn27g20s8s517cykghycxps0bydqargx7687w6d320yb";
      type = "gem";
    };
    version = "1.0.3";
  };
  memcached = {
    source = {
      sha256 = "0cbjisgc50s4scmp50zq7mrw4wdd9r69jhcbw3wwfr1zi2iv2xpj";
      type = "gem";
    };
    version = "1.8.0";
  };
  mime-types = {
    source = {
      sha256 = "03j98xr0qw2p2jkclpmk7pm29yvmmh0073d8d43ajmr0h3w7i5l9";
      type = "gem";
    };
    version = "2.99.3";
  };
  minitest = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0icglrhghgwdlnzzp4jf76b0mbc71s80njn5afyfjn4wqji8mqbq";
      type = "gem";
    };
    version = "5.11.3";
  };
  mixlib-cli = {
    source = {
      sha256 = "0647msh7kp7lzyf6m72g6snpirvhimjm22qb8xgv9pdhbcrmcccp";
      type = "gem";
    };
    version = "1.7.0";
  };
  mongo = {
    dependencies = ["bson"];
    source = {
      sha256 = "0y0axsmd8x7f1417hd257r6bb4k4n3rgb5188bqcsyp082jgp85j";
      type = "gem";
    };
    version = "1.12.3";
  };
  multi_json = {
    source = {
      sha256 = "1rf3l4j3i11lybqzgq2jhszq7fh7gpmafjzd14ymp9cjfxqg596r";
      type = "gem";
    };
    version = "1.11.2";
  };
  multipart-post = {
    source = {
      sha256 = "09k0b3cybqilk1gwrwwain95rdypixb2q9w65gd44gfzsd84xi1x";
      type = "gem";
    };
    version = "2.0.0";
  };
  mysql = {
    source = {
      sha256 = "1y2b5rnspa0lllvqd6694hbkjhdn45389nrm3xfx6xxx6gf35p36";
      type = "gem";
    };
    version = "2.9.1";
  };
  mysql2 = {
    source = {
      sha256 = "0dap507ba8pj3hpc3y8ammsq51xqflb54p5g262m1z55y6m7fm6k";
      type = "gem";
    };
    version = "0.3.18";
  };
  net-ping = {
    source = {
      sha256 = "19p3d39109xvbr4dcjs3g3zliazhc1k3iiw69mgb1w204hc7wkih";
      type = "gem";
    };
    version = "1.7.8";
  };
  netrc = {
    source = {
      sha256 = "0gzfmcywp1da8nzfqsql2zqi648mfnx6qwkig3cv36n9m0yy676y";
      type = "gem";
    };
    version = "0.11.0";
  };
  oj = {
    source = {
      sha256 = "1zyb8clpk7hlqym1i8gjc6b2zi2fb732k5sbhxmnw6ijdgkvhwbm";
      type = "gem";
    };
    version = "3.0.5";
  };
  pg = {
    source = {
      sha256 = "00g33hdixgync6gp4mn0g0kjz5qygshi47xw58kdpd9n5lzdpg8c";
      type = "gem";
    };
    version = "0.18.3";
  };
  rack = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "03w1ri5l91q800f1bdcdl5rbagy7s4kml136b42s2lmxmznxhr07";
      type = "gem";
    };
    version = "1.6.9";
  };
  rack-protection = {
    dependencies = ["rack"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1cn0c7f94jg48znrmjpayywfplma83l3lgx918g1ajpn63mq6dgm";
      type = "gem";
    };
    version = "1.5.4";
  };
  redis = {
    source = {
      sha256 = "16jzlqp80qiqg5cdc9l144n6k3c5qj9if4pgij87sscn8ahi993k";
      type = "gem";
    };
    version = "3.2.1";
  };
  rest-client = {
    dependencies = ["http-cookie" "mime-types" "netrc"];
    source = {
      sha256 = "1m8z0c4yf6w47iqz6j2p7x1ip4qnnzvhdph9d5fgx081cvjly3p7";
      type = "gem";
    };
    version = "1.8.0";
  };
  ruby-supervisor = {
    source = {
      sha256 = "07g0030sb9psrnz3b8axyjrcgwrmd38p0m05nq24bvrlvav4vkc0";
      type = "gem";
    };
    version = "0.0.2";
  };
  sensu = {
    dependencies = ["async_sinatra" "em-redis-unified" "eventmachine" "multi_json" "sensu-extension" "sensu-extensions" "sensu-logger" "sensu-settings" "sensu-spawn" "sensu-transport" "sinatra" "thin" "uuidtools"];
    source = {
      sha256 = "0vyk8m4acjzn4i2q41gabpmrlqcl2x4ivf58m0hqn3x7l45ma605";
      type = "gem";
    };
    version = "0.22.1";
  };
  sensu-extension = {
    dependencies = ["eventmachine"];
    source = {
      sha256 = "1ms7g76vng0dzaq86g4s8mdszjribm6v6vkbmh4psf988xw95a2b";
      type = "gem";
    };
    version = "1.3.0";
  };
  sensu-extensions = {
    dependencies = ["multi_json" "sensu-extension" "sensu-logger" "sensu-settings"];
    source = {
      sha256 = "16npdf1hcpcn47wmznkwcikynxzb2jv2irqlvprjlapy2m6m4c62";
      type = "gem";
    };
    version = "1.4.0";
  };
  sensu-logger = {
    dependencies = ["eventmachine" "multi_json"];
    source = {
      sha256 = "1pbzbr83df4awndr49f1z7z1bl9n73nkf1xcnlkjcnpnb3yy07pw";
      type = "gem";
    };
    version = "1.1.0";
  };
  sensu-plugin = {
    dependencies = ["json" "mixlib-cli"];
    source = {
      sha256 = "1k8mkkwb70z2j5lq457y7lsh5hr8gzd53sjbavpqpfgy6g4bxrg8";
      type = "gem";
    };
    version = "1.2.0";
  };
  sensu-plugins-disk-checks = {
    dependencies = ["sensu-plugin" "sys-filesystem"];
    source = {
      sha256 = "0d2qcn2ffirvnrnpw98kll412jy7plhg5x2kkpky79a8nx8bbnp5";
      type = "gem";
    };
    version = "1.1.3";
  };
  sensu-plugins-dns = {
    dependencies = ["dnsruby" "sensu-plugin"];
    source = {
      sha256 = "0267cr8lxim2cypqn3dbjz8r5kzbzadbkssx790z1ssncjgl8qa9";
      type = "gem";
    };
    version = "0.0.6";
  };
  sensu-plugins-elasticsearch = {
    dependencies = ["aws-es-transport" "aws-sdk" "elasticsearch" "rest-client" "sensu-plugin"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1cz7ky6c2bc1kc5w4i7ar95d3jfh5jaqddsnfqcj3mlm2i5jl7p6";
      type = "gem";
    };
    version = "1.12.0";
  };
  sensu-plugins-entropy-checks = {
    dependencies = ["sensu-plugin"];
    source = {
      sha256 = "1sk9hkwzhx8vy0jy4gq9igadixbjzw3fvskskl29xcs92cqk1j32";
      type = "gem";
    };
    version = "0.0.3";
  };
  sensu-plugins-logs = {
    dependencies = ["sensu-plugin"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1sd9gqdvw1iy8vykilxfa0vwx45avk8inlqwsqhi8g3sm9j3yp4g";
      type = "gem";
    };
    version = "1.3.1";
  };
  sensu-plugins-mailer = {
    dependencies = ["aws" "erubis" "mail" "mailgun-ruby" "sensu-plugin"];
    source = {
      sha256 = "0ysqwssa5jfn1wgsn9pmqiy85swkmk87xki4i7q3w260rl138bf9";
      type = "gem";
    };
    version = "0.1.2";
  };
  sensu-plugins-memcached = {
    dependencies = ["memcached" "sensu-plugin"];
    source = {
      sha256 = "1n355hycsva61fvcc9vs1bi4qr23pbyl3gmpkxgic4hz4nm2lhny";
      type = "gem";
    };
    version = "0.0.3";
  };
  sensu-plugins-mongodb = {
    dependencies = ["bson" "bson_ext" "mongo" "sensu-plugin"];
    source = {
      sha256 = "120ay9kclypqf3rx4xv2cgay0hi8hvql0xzlfpyamxvbgqdfn532";
      type = "gem";
    };
    version = "0.0.8";
  };
  sensu-plugins-mysql = {
    dependencies = ["aws" "inifile" "mysql" "mysql2" "sensu-plugin"];
    source = {
      sha256 = "0j4bqm4wi8i86cbpbmrp88q71bzcmsfaf4icb2ml4w2db0ccr2d9";
      type = "gem";
    };
    version = "0.0.4";
  };
  sensu-plugins-network-checks = {
    dependencies = ["activesupport" "dnsbl-client" "net-ping" "sensu-plugin" "whois"];
    source = {
      sha256 = "1n474lg1fdjd9908dfwdhs1d18rj2g11fqf1sp761addg3rlh0wx";
      type = "gem";
    };
    version = "0.1.4";
  };
  sensu-plugins-postgres = {
    dependencies = ["dentaku" "pg" "sensu-plugin"];
    source = {
      sha256 = "1xh2gzpacmzrzxj7ibczdrzgf3hdja0yl5cskfqypiq007d48gr9";
      type = "gem";
    };
    version = "0.0.7";
  };
  sensu-plugins-redis = {
    dependencies = ["redis" "sensu-plugin"];
    source = {
      sha256 = "0v3gasiz3hgp6r4yzhalpqk2g4kcqqism01c3apyzcn0f6pvp3z7";
      type = "gem";
    };
    version = "0.1.0";
  };
  sensu-plugins-ssl = {
    dependencies = ["rest-client" "sensu-plugin"];
    source = {
      sha256 = "15md1czbvpw1d63x91k1x4rwhsgd88shmx0pv8083bywl2c87yqq";
      type = "gem";
    };
    version = "0.0.6";
  };
  sensu-plugins-supervisor = {
    dependencies = ["libxml-xmlrpc" "ruby-supervisor" "sensu-plugin"];
    source = {
      sha256 = "1idds9x01ccxldzi00xz5nx3jizdn3ywm1ijwmw2yb6zb171k0zi";
      type = "gem";
    };
    version = "0.0.3";
  };
  sensu-plugins-systemd = {
    dependencies = ["sensu-plugin"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0f0hdp2cvzs5wby2fkjg48siyjgdi83hf11ld1by2l0cn4s9ir24";
      type = "gem";
    };
    version = "0.1.0";
  };
  sensu-settings = {
    dependencies = ["multi_json"];
    source = {
      sha256 = "0fk5chvzv946yg6cqpjlpjw5alwimg8rsxs3knhbgdanyrbh6m32";
      type = "gem";
    };
    version = "3.3.0";
  };
  sensu-spawn = {
    dependencies = ["childprocess" "em-worker" "eventmachine"];
    source = {
      sha256 = "06krhrgdb1b83js185ljh32sd30r8irfb1rjs0wl2amn6w5nrdi6";
      type = "gem";
    };
    version = "1.7.0";
  };
  sensu-transport = {
    dependencies = ["amq-protocol" "amqp" "em-redis-unified" "eventmachine"];
    source = {
      sha256 = "153r2wgqh2bxrgml2ag7iyw7w5r4jmcbqj96lcq5gr98761zzb8l";
      type = "gem";
    };
    version = "4.0.0";
  };
  sinatra = {
    dependencies = ["rack" "rack-protection" "tilt"];
    source = {
      sha256 = "1hhmwqc81ram7lfwwziv0z70jh92sj1m7h7s9fr0cn2xq8mmn8l7";
      type = "gem";
    };
    version = "1.4.6";
  };
  sys-filesystem = {
    dependencies = ["ffi"];
    source = {
      sha256 = "08zi702aq7cgm3wmmai2f18ph30yvincnlk1crza8axrjvf7fr25";
      type = "gem";
    };
    version = "1.1.5";
  };
  thin = {
    dependencies = ["daemons" "eventmachine" "rack"];
    source = {
      sha256 = "1m56aygh5rh8ncp3s2gnn8ghn5ibkk0bg6s3clmh1vzaasw2lj4i";
      type = "gem";
    };
    version = "1.6.3";
  };
  thread_safe = {
    source = {
      sha256 = "0nmhcgq6cgz44srylra07bmaw99f5271l0dpsvl5f75m44l0gmwy";
      type = "gem";
    };
    version = "0.3.6";
  };
  tilt = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0020mrgdf11q23hm1ddd6fv691l51vi10af00f137ilcdb2ycfra";
      type = "gem";
    };
    version = "2.0.8";
  };
  tzinfo = {
    dependencies = ["thread_safe"];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1fjx9j327xpkkdlxwmkl3a8wqj7i4l4jwlrv3z13mg95z9wl253z";
      type = "gem";
    };
    version = "1.2.5";
  };
  unf = {
    dependencies = ["unf_ext"];
    source = {
      sha256 = "0bh2cf73i2ffh4fcpdn9ir4mhq8zi50ik0zqa1braahzadx536a9";
      type = "gem";
    };
    version = "0.1.4";
  };
  unf_ext = {
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "06p1i6qhy34bpb8q8ms88y6f2kz86azwm098yvcc0nyqk9y729j1";
      type = "gem";
    };
    version = "0.0.7.5";
  };
  uuidtools = {
    source = {
      sha256 = "0zjvq1jrrnzj69ylmz1xcr30skf9ymmvjmdwbvscncd7zkr8av5g";
      type = "gem";
    };
    version = "2.1.5";
  };
  whois = {
    dependencies = ["activesupport"];
    source = {
      sha256 = "1ckr4w1gba1m1yabl2piy7y9wy3hc0gzdxnqkr74ffk5xqbn0k49";
      type = "gem";
    };
    version = "3.6.3";
  };
  xml-simple = {
    source = {
      sha256 = "0xlqplda3fix5pcykzsyzwgnbamb3qrqkgbrhhfz2a2fxhrkvhw8";
      type = "gem";
    };
    version = "1.1.5";
  };
}