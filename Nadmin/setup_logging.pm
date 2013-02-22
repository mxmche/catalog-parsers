package Nadmin::setup_logging;

use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(setup_logging);

my $logfile;

# Redirect warn/die messages to a dedicated file.  Anything sent to
# stderr (including output from subprocesses) goes there as well,
# though not nicely timestamped.  warn/die send nothing to former
# stderr or stdout.
#
# Argument: LOGFILE or PREFIX (LOGFILE is distinguished by the leading
# slash).  If LOGFILE is not specified, errors go to STDERR as usual,
# but prefixed and timestamped.  If LOGFILE is specified, you cannot
# give PREFIX -- and indeed, what's the use of the prefix in dedicated
# logfile?  On the other hand, when outputting to STDERR (like sensors
# under main process), prefix is useful.

sub setup_logging
{
    my ($arg) = @_;
    my $prefix = "";

    if ($arg =~ m%^/%) {
        $logfile = $arg;
    }
    else {
        $prefix = "$arg ";
    }

    $SIG{__WARN__} = sub {
        open_file_if_nec ();
        #my @x = prepare_log_args();
        warn scalar(localtime(time)), " $prefix", @_;
    };
    $SIG{__DIE__} = sub {
        # If called from an eval, this it not die() but a kind of throw.
        my ($package, $filename, $line, $subroutine) = caller (1);
        die @_ if $subroutine eq "(eval)";
        open_file_if_nec ();
        #my @x = prepare_log_args();
        confess scalar(localtime(time)), " $prefix", @_;
    };
}

# via ENV we can set additional arguments to warn or die, eg PID,
# SSID, LOGNAME.
# this function returns array of strings
sub prepare_log_args
{
    my @x;

    if ($ENV{NADMIN_PID}) {
        push @x, " [$ENV{NADMIN_PID}]";
    }
    if ($ENV{NADMIN_SSID}) {
        push @x, " [sid: $ENV{NADMIN_SSID}]";
    }
    if ($ENV{NADMIN_LOGNAME}) {
        if ($ENV{NADMIN_LOGORG}) {
            push @x, " [auth: $ENV{NADMIN_LOGNAME} $ENV{NADMIN_LOGORG}]";
            delete $ENV{NADMIN_LOGORG};
        }
        else {
            push @x, " [auth: $ENV{NADMIN_LOGNAME}]";
        }
        delete $ENV{NADMIN_LOGNAME};
    }
    return @x;
}

sub open_file_if_nec
{
    my $file = $logfile || return;
    if ((stat STDERR)[1] != (stat $file)[1]) {
        # inode numbers do not match -- file rotated.
        # Switch to new one.
        open (STDERR, ">>$file") or die ("$file: $!");
    }
}

1;
