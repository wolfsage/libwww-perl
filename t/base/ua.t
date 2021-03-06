use strict;
use warnings;
use Test::More;

use LWP::UserAgent;
plan tests => 35;

# Prevent environment from interfering with test:
delete $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
delete $ENV{HTTPS_CA_FILE};
delete $ENV{HTTPS_CA_DIR};
delete $ENV{PERL_LWP_SSL_CA_FILE};
delete $ENV{PERL_LWP_SSL_CA_PATH};
delete $ENV{PERL_LWP_ENV_PROXY};

my $ua = LWP::UserAgent->new;

my $clone = $ua->clone;

like($ua->agent, qr/^libwww-perl/, '$ua->agent');
ok(!defined $ua->proxy(ftp => "http://www.sol.no"), '$ua->proxy(ftp => "http://www.sol.no")');
is($ua->proxy("ftp"), "http://www.sol.no", '$ua->proxy("ftp")');

my @a = $ua->proxy([qw(ftp http wais)], "http://proxy.foo.com");
for (@a) { $_ = "undef" unless defined; }

is("@a", "http://www.sol.no undef undef", '$ua->proxy([qw(ftp http wais)], "http://proxy.foo.com")');
is($ua->proxy("http"), "http://proxy.foo.com", '$ua->proxy("http")');
is(ref($ua->default_headers), "HTTP::Headers", 'ref($ua->default_headers)');

$ua->default_header("Foo" => "bar", "Multi" => [1, 2]);
is($ua->default_headers->header("Foo"), "bar", '$ua->default_headers->header("Foo")');
is($ua->default_header("Foo"),          "bar", '$ua->default_header("Foo")');

# Try it
$ua->proxy(http => "loopback:");
$ua->agent("foo/0.1");
is($ua->get("http://www.example.com", x => "y")->content, <<EOT , "Full \$ua->get->content");
GET http://www.example.com
User-Agent: foo/0.1
Foo: bar
Multi: 1
Multi: 2
X: y

EOT

is(ref($clone->{proxy}), 'HASH', 'ref($clone->{proxy})');

is($ua->proxy(http => undef), "loopback:", '$ua->proxy(http => undef)');
is($ua->proxy('http'), undef, "\$ua->proxy('http')");

my $res = $ua->get("data:text/html,%3Chtml%3E%3Chead%3E%3Cmeta%20http-equiv%3D%22Content-Script-Type%22%20content%3D%22text%2Fjavascript%22%3E%3Cmeta%20http-equiv%3D%22Content-Style-Type%22%20content%3D%22text%2Fcss%22%3E%3C%2Fhead%3E%3C%2Fhtml%3E");
ok($res->header("Content-Style-Type", "text/css"),         '$res->header("Content-Style-Type", "text/css")');
ok($res->header("Content-Script-Type", "text/javascript"), '$res->header("Content-Script-Type", "text/javascript")');

is(join(":", $ua->ssl_opts), "verify_hostname", '$ua->ssl_opts');
is($ua->ssl_opts("verify_hostname"),          1, '$ua->ssl_opts("verify_hostname")');
is($ua->ssl_opts("verify_hostname" => 0),     1, '$ua->ssl_opts("verify_hostname" => 0)');
is($ua->ssl_opts("verify_hostname"),          0, '$ua->ssl_opts("verify_hostname")');
is($ua->ssl_opts("verify_hostname" => undef), 0, '$ua->ssl_opts("verify_hostname" => undef)');
is($ua->ssl_opts("verify_hostname"),      undef, '$ua->ssl_opts("verify_hostname")');
is(join(":", $ua->ssl_opts), "", '$ua->ssl_opts');

$ua = LWP::UserAgent->new(ssl_opts => {});
is($ua->ssl_opts("verify_hostname"),      1, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
is($ua->ssl_opts("verify_hostname"),      0, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { SSL_ca_file => 'cert.dat'});
is($ua->ssl_opts("verify_hostname"),      1, '$ua->ssl_opts("verify_hostname")');
is($ua->ssl_opts("SSL_ca_file"), 'cert.dat', '$ua->ssl_opts("SSL_ca_file")');

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 1;
$ua = LWP::UserAgent->new();
is($ua->ssl_opts("verify_hostname"), 1, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => {});
is($ua->ssl_opts("verify_hostname"), 1, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
is($ua->ssl_opts("verify_hostname"), 0, '$ua->ssl_opts("verify_hostname")');

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
$ua = LWP::UserAgent->new();
is($ua->ssl_opts("verify_hostname"), 0, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => {});
is($ua->ssl_opts("verify_hostname"), 0, '$ua->ssl_opts("verify_hostname")');

$ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
is($ua->ssl_opts("verify_hostname"), 1, '$ua->ssl_opts("verify_hostname")');

delete @ENV{grep /_proxy$/i, keys %ENV}; # clean out any proxy vars

$ENV{http_proxy} = "http://example.com";
$ua = LWP::UserAgent->new;
is($ua->proxy('http'),                undef, "\$ua->proxy('http')");
$ua = LWP::UserAgent->new(env_proxy => 1);;
is($ua->proxy('http'), "http://example.com", "\$ua->proxy('http')");

$ENV{PERL_LWP_ENV_PROXY} = 1;
$ua = LWP::UserAgent->new();
is($ua->proxy('http'), "http://example.com", "\$ua->proxy('http')");
$ua = LWP::UserAgent->new(env_proxy => 0);
is($ua->proxy('http'),                undef, "\$ua->proxy('http')");
