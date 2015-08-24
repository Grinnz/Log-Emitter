use strict;
use warnings;

use Test::More;
use Encode 'decode';
use File::Spec::Functions 'catdir';
use File::Temp 'tempdir';
use Log::Emitter;

BEGIN {
  eval "use Log::Contextual ':log', 'set_logger', -levels => [qw(debug info warn error fatal)]; 1"
    or plan skip_all => 'Log::Contextual required for these tests';
}

my $dir = tempdir CLEANUP => 1;
my $path = catdir $dir, 'test.log';
my $logger = Log::Emitter->new(path => $path);

set_logger $logger;

log_debug { 'message 1' };
log_info { 'message 2' };
log_warn { 'message 3' };
log_error { 'message 4' };
log_fatal { 'message 5' };

my $content;
{
  local $/;
  open my $fh, '<', $path;
  $content = decode 'UTF-8', readline $fh;
}

like $content, qr/\[.*\] \[debug\] message 1/, 'right log message';
like $content, qr/\[.*\] \[info\] message 2/,  'right log message';
like $content, qr/\[.*\] \[warn\] message 3/,  'right log message';
like $content, qr/\[.*\] \[error\] message 4/, 'right log message';
like $content, qr/\[.*\] \[fatal\] message 5/, 'right log message';

done_testing;
