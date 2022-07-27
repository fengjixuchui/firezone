# frozen_string_literal: true

#
# Copyright:: Chef Software, Inc.
# Copyright:: Firezone
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name 'erlang'

# Erlang 25 has SSL issues -- HTTPoison times out to some servers, e.g. Azure https://login.microsoftonline.com
default_version '25.0.2'

license 'Apache-2.0'
license_file 'LICENSE.txt'
skip_transitive_dependency_licensing true

dependency 'gawk'
dependency 'automake'
dependency 'autoconf'
dependency 'zlib'
dependency 'openssl'
dependency 'config_guess'

# grab from github so we can get patch releases if we need to
source url: "https://github.com/erlang/otp/archive/OTP-#{version}.tar.gz"
relative_path "otp-OTP-#{version}"

# versions_list: https://github.com/erlang/otp/tags filter=*.tar.gz
version('25.0.2')    { source sha256: 'f78764c6fd504f7b264c47e469c0fcb86a01c92344dc9d625dfd42f6c3ed8224' }
version('25.0.1')    { source sha256: '4426bdf717c9f359f592fceb5dc29b9cab152010cd258475730de4582de42bff' }
version('25.0')      { source sha256: '5988e3bca208486494446e885ca2149fe487ee115cbc3770535fd22a795af5d2' }
version('24.3.4')    { source sha256: 'e59bedbb871af52244ca5284fd0a572d52128abd4decf4347fe2aef047b65c58' }
version('24.2.1')    { source sha256: '2854318d12d727fc508e8fd5fe6921c0cbc7727d1183ad8f6f808585496e42d6' }
version('24.2')      { source sha256: '0b9c9ba7d8b40f6c77d529e07561b10f0914d2bfe9023294d7eda85b62936792' }
version('24.1.4')    { source sha256: 'aa31ba689740dc446dfa5bb256474df5fb5e5459b981b4d2155afa91010ca66a' }
version('24.0.6')    { source sha256: 'a60a7d776a4573e2018d6fad6df957e3911ecbce5f11497a8ec537f613aca0a1' }
version('24.0.5')    { source sha256: 'dd189cf94bf86c610a66f5d9f1a49b8d95a7ce1a7534d216e97e8fade271e624' }
version('23.3.3')    { source sha256: '839d74e71a457295d95b8674f1848a5d7d9c4c274a041ef8026d035da88858ae' }
version('23.3.2')    { source sha256: '02443dd42023d0eb73f73dc05f4d3ded7bc4ab59d348041a37a045ba1581b48b' }
version('22.2')      { source sha256: '232c37a502c7e491a9cbf86acb7af64fbc1a793fcbcbd0093cb029cf1c3830a7' }
version('22.1.8')    { source sha256: '7302be70cee2c33689bf2c2a3e7cfee597415d0fb3e4e71bd3e86bd1eff9cfdc' }
version('21.3.8.11') { source sha256: 'aab77124285820608cd7a90f6b882e42bb5739283e10a8593d7f5bce9b30b16a' }
version('21.1')      { source sha256: '7212f895ae317fa7a086fa2946070de5b910df5d41263e357d44b0f1f410af0f' }
version('20.3.8.9')  { source sha256: '897dd8b66c901bfbce09ed64e0245256aca9e6e9bdf78c36954b9b7117192519' }
version('20.0')      { source sha256: '22710927ad2e48a0964997bf5becb24abb1f4fed86f5f05af22a9e1df636b787' }
version('19.3.6.11') { source sha256: 'c857ea6d2c901bfb633d9ceeb5e05332475357f185dd5112b7b6e4db80072827' }
version('18.3.4.9')  { source sha256: '25ef8ba3824cb726c4830abf32c2a2967925b1e33a8e8851dba596e933e2689a' }
version('18.3')      { source sha256: 'a6d08eb7df06e749ccaf3049b33ceae617a3c466c6a640ee8d248c2372d48f4e' }
version('18.2')      { source sha256: '3944ce41d13fbef1e1e80d7335b2167849e8566581513d5d9226cd211d3d58f9' }
version('18.1')      { source sha256: '6b956dda690d3f3bf244249e8d422dd606231cc7229675bf5e34b5ba2ae83e9b' }

# rubocop:disable Metrics/BlockLength
build do
  # Deprecated
  # if version.satisfies?('>= 18.3')
  #   # Don't listen on 127.0.0.1/::1 implicitly whenever ERL_EPMD_ADDRESS is given
  #   patch source: 'epmd-require-explicitly-adding-loopback-address.patch', plevel: 1
  # end

  env = with_standard_compiler_flags(with_embedded_path).merge(
    'CFLAGS' => "-O2 -g -L#{install_dir}/embedded/lib -I#{install_dir}/embedded/erlang/include",
    'LDFLAGS' => "-Wl,-rpath #{install_dir}/embedded/lib -L#{install_dir}/embedded/lib -I#{install_dir}/embedded/er"\
      'lang/include'
  )
  env.delete('CPPFLAGS')

  # The TYPE env var sets the type of emulator you want
  # We want the default so we give TYPE and empty value
  # in case it was set by CI.
  env['TYPE'] = ''

  update_config_guess(target: 'erts/autoconf')
  update_config_guess(target: 'lib/common_test/priv/auxdir')
  update_config_guess(target: 'lib/erl_interface/src/auxdir')
  update_config_guess(target: 'lib/wx/autoconf')

  if version.satisfies?('>= 19.0')
    update_config_guess(target: 'lib/common_test/test_server/src')
  else
    update_config_guess(target: 'lib/test_server/src')
  end

  # Setup the erlang include dir
  mkdir "#{install_dir}/embedded/erlang/include"

  # At this time, erlang does not expose a way to specify the path(s) to these
  # libraries, but it looks in its local +include+ directory as part of the
  # search, so we will symlink them here so they are picked up.
  #
  # In future releases of erlang, someone should check if these flags (or
  # environment variables) are avaiable to remove this ugly hack.
  %w[openssl zlib.h zconf.h].each do |name|
    link "#{install_dir}/embedded/include/#{name}", "#{install_dir}/embedded/erlang/include/#{name}"
  end

  # Note 2017-02-28 sr: HiPE doesn't compile with OTP 18.3 on ppc64le (https://bugs.erlang.org/browse/ERL-369)
  # Compiling fails when linking beam.smp, with
  #     powerpc64le-linux-gnu/libutil.so: error adding symbols: File in wrong format
  #
  # We've been having issues with ppc64le and hipe before, too:
  # https://github.com/chef/chef-server/commit/4fa25ed695acaf819b11f71c6db1aab5c8adcaee
  #
  # It's trying to compile using a linker script for ppc64, it seems:
  # https://github.com/erlang/otp/blob/c1ea854fac3d8ed14/erts/emulator/hipe/elf64ppc.x
  # Probably introduced with https://github.com/erlang/otp/commit/37d63e9b8a0a96
  # See also https://sourceware.org/ml/binutils/2015-05/msg00148.html
  hipe = ppc64le? ? 'disable' : 'enable'

  unless File.exist?('./configure')
    # Building from github source requires this step
    command './otp_build autoconf'
  end
  # NOTE: et, debugger and observer applications require wx to
  # build. The tarballs from the downloads site has prebuilt the beam
  # files, so we were able to get away without disabling them and
  # still build. When building from raw source we must disable them
  # explicitly.
  wx = 'without'

  command './configure' \
          ' --prefix=/opt/runner/local' \
          ' --enable-threads' \
          ' --enable-smp-support' \
          ' --enable-kernel-poll' \
          ' --enable-dynamic-ssl-lib' \
          ' --enable-shared-zlib' \
          ' --enable-fips' \
          " --#{hipe}-hipe" \
          " --#{wx}-wx" \
          " --#{wx}-et" \
          " --#{wx}-debugger" \
          " --#{wx}-observer" \
          ' --without-termcap' \
          ' --without-megaco' \
          ' --without-javac' \
          " --with-ssl=#{install_dir}/embedded" \
          ' --disable-debug', env: env

  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env
end
# rubocop:enable Metrics/BlockLength
