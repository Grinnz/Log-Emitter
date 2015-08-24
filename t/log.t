use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec::Functions 'catdir';
use File::Temp 'tempdir';
use Log::Emitter;
use Encode 'decode';

# Logging to file
my $dir = tempdir CLEANUP => 1;
my $wrongpath = catdir $dir, 'wrong.log';
my $log = Log::Emitter->new(level => 'error', path => $wrongpath);
$log->error('wrong file');

my $path = catdir $dir, 'test.log';
$log->path($path);
$log->error('Just works');
$log->fatal('I ♥ Logging');
$log->debug('Does not work');
undef $log;

my $content;
{
  local $/;
  open my $fh, '<', $path or die "Error opening temp file for reading: $!";
  $content = decode 'UTF-8', readline($fh);
}
like $content,   qr/\[.*\] \[error\] Just works/,        'right error message';
like $content,   qr/\[.*\] \[fatal\] I ♥ Logging/, 'right fatal message';
unlike $content, qr/\[.*\] \[debug\] Does not work/,     'no debug message';

# Logging to STDERR
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDERR = $handle;
  my $log = Log::Emitter->new;
  $log->error('Just works');
  $log->fatal('I ♥ Logging');
  $log->debug('Works too');
}
$content = decode 'UTF-8', $buffer;
like $content, qr/\[.*\] \[error\] Just works\n/,        'right error message';
like $content, qr/\[.*\] \[fatal\] I ♥ Logging\n/, 'right fatal message';
like $content, qr/\[.*\] \[debug\] Works too\n/,         'right debug message';

# Formatting
$log = Log::Emitter->new;
like $log->format->(time, 'debug', 'Test 123'),
  qr/^\[.*\] \[debug\] Test 123\n$/, 'right format';
like $log->format->(time, 'debug', qw(Test 1 2 3)),
  qr/^\[.*\] \[debug\] Test\n1\n2\n3\n$/, 'right format';
like $log->format->(time, 'error', 'I ♥ Logging'),
  qr/^\[.*\] \[error\] I ♥ Logging\n$/, 'right format';
$log->format(
  sub {
    my ($time, $level, @lines) = @_;
    return join ':', $level, $time, @lines;
  }
);
like $log->format->(time, 'debug', qw(Test 1 2 3)),
  qr/^debug:\d+:Test:1:2:3$/, 'right format';

# Events
$log = Log::Emitter->new;
my $msgs = [];
$log->unsubscribe('message')->on(
  message => sub {
    my ($log, $level, @lines) = @_;
    push @$msgs, $level, @lines;
  }
);
$log->debug('Test', 1, 2, 3);
is_deeply $msgs, [qw(debug Test 1 2 3)], 'right message';
$msgs = [];
$log->info('Test', 1, 2, 3);
is_deeply $msgs, [qw(info Test 1 2 3)], 'right message';
$msgs = [];
$log->warn('Test', 1, 2, 3);
is_deeply $msgs, [qw(warn Test 1 2 3)], 'right message';
$msgs = [];
$log->error('Test', 1, 2, 3);
is_deeply $msgs, [qw(error Test 1 2 3)], 'right message';
$msgs = [];
$log->fatal('Test', 1, 2, 3);
is_deeply $msgs, [qw(fatal Test 1 2 3)], 'right message';

# History
$buffer = '';
my $history;
{
  open my $handle, '>', \$buffer;
  local *STDERR = $handle;
  my $log = Log::Emitter->new;
  $log->max_history_size(2);
  $log->level('info');
  $log->error('First');
  $log->fatal('Second');
  $log->debug('Third');
  $log->info('Fourth', 'Fifth');
  $history = $log->history;
}
$content = decode 'UTF-8', $buffer;
like $content,   qr/\[.*\] \[error\] First\n/,        'right error message';
like $content,   qr/\[.*\] \[info\] Fourth\nFifth\n/, 'right info message';
unlike $content, qr/debug/,                           'no debug message';
like $history->[0][0], qr/^\d+$/, 'right epoch time';
is $history->[0][1],   'fatal',   'right level';
is $history->[0][2],   'Second',  'right message';
is $history->[1][1],   'info',    'right level';
is $history->[1][2],   'Fourth',  'right message';
is $history->[1][3],   'Fifth',   'right message';
ok !$history->[2], 'no more messages';

# "debug"
$log->level('debug');
is $log->level, 'debug', 'right level';
ok $log->is_debug, '"debug" log level is active';
ok $log->is_info,  '"info" log level is active';
ok $log->is_warn,  '"warn" log level is active';
ok $log->is_error, '"error" log level is active';

# "info"
$log->level('info');
is $log->level, 'info', 'right level';
ok !$log->is_debug, '"debug" log level is inactive';
ok $log->is_info,  '"info" log level is active';
ok $log->is_warn,  '"warn" log level is active';
ok $log->is_error, '"error" log level is active';

# "warn"
$log->level('warn');
is $log->level, 'warn', 'right level';
ok !$log->is_debug, '"debug" log level is inactive';
ok !$log->is_info,  '"info" log level is inactive';
ok $log->is_warn,  '"warn" log level is active';
ok $log->is_error, '"error" log level is active';

# "error"
$log->level('error');
is $log->level, 'error', 'right level';
ok !$log->is_debug, '"debug" log level is inactive';
ok !$log->is_info,  '"info" log level is inactive';
ok !$log->is_warn,  '"warn" log level is inactive';
ok $log->is_error, '"error" log level is active';

# "fatal"
$log->level('fatal');
is $log->level, 'fatal', 'right level';
ok !$log->is_debug, '"debug" log level is inactive';
ok !$log->is_info,  '"info" log level is inactive';
ok !$log->is_warn,  '"warn" log level is inactive';
ok !$log->is_error, '"error" log level is inactive';

done_testing();
